import { strict as assert } from "node:assert";
import test from "node:test";
import { authorize, buildComment, codeBlock, getBlocker, isCommand, isOwnFork } from "./resolveDmi.js";

const AUTHOR = { id: 10, login: "author" };
const SOMEONE = { id: 20, login: "someone" };
const ORG_REPO = { id: 1, full_name: "org/lc13", owner: { id: 30 } };
const FORK_REPO = { id: 2, full_name: "author/lc13", owner: { id: AUTHOR.id } };

const makePull = (overrides = {}) => ({
	state: "open",
	maintainer_can_modify: true,
	user: AUTHOR,
	head: { sha: "abc", ref: "icons", repo: FORK_REPO },
	base: { ref: "master", repo: ORG_REPO },
	...overrides,
});

const run = async ({ body = "/resolve-dmi", permission = "write", pull = makePull(), user = SOMEONE } = {}) => {
	const outputs = {};
	const comments = [];
	const github = {
		rest: {
			repos: { getCollaboratorPermissionLevel: async () => ({ data: { permission } }) },
			pulls: { get: async () => ({ data: pull }) },
			issues: { createComment: async ({ body }) => comments.push(body) },
			reactions: { createForIssueComment: async () => {} },
		},
	};
	const context = {
		repo: { owner: "org", repo: "lc13" },
		payload: {
			comment: { id: 1, body, user },
			issue: { number: 5 },
			repository: { default_branch: "master" },
		},
	};
	const core = { setOutput: (key, value) => (outputs[key] = value) };
	await authorize({ github, context, core });
	return { outputs, comments };
};

test("only the exact command is accepted", () => {
	assert.equal(isCommand("/resolve-dmi"), true);
	assert.equal(isCommand("  /resolve-dmi\r\n"), true);
	assert.equal(isCommand("please /resolve-dmi"), false);
	assert.equal(isCommand("/resolve-dmi-foo"), false);
	assert.equal(isCommand("> /resolve-dmi"), false);
	assert.equal(isCommand(null), false);
});

test("maintainers are allowed", async () => {
	for (const permission of ["write", "admin"]) {
		const { outputs, comments } = await run({ permission });
		assert.deepEqual(outputs, {
			proceed: "true",
			head_sha: "abc",
			head_ref: "icons",
			head_repo: "author/lc13",
			base_ref: "master",
		});
		assert.deepEqual(comments, []);
	}
});

test("everyone else is silently ignored", async () => {
	for (const permission of ["read", "none"]) {
		const { outputs, comments } = await run({ permission });
		assert.deepEqual(outputs, { proceed: "false" });
		assert.deepEqual(comments, []);
	}
});

test("authors are allowed on pull requests from their own fork", async () => {
	const { outputs } = await run({ permission: "read", user: AUTHOR });
	assert.equal(outputs.proceed, "true");
});

test("authors still need maintainer edits to be enabled", async () => {
	const pull = makePull({ maintainer_can_modify: false });
	const { outputs, comments } = await run({ permission: "read", user: AUTHOR, pull });
	assert.deepEqual(outputs, { proceed: "false" });
	assert.match(comments[0], /Allow edits by maintainers/);
});

test("authors can't push to branches they don't own", async () => {
	const head = (repo) => makePull({ head: { sha: "abc", ref: "icons", repo } });
	const others = [
		// a branch in the main repository, if they've since lost write access
		head(ORG_REPO),
		// another user's fork
		head({ id: 3, full_name: "other/lc13", owner: { id: 40 } }),
		// a deleted fork
		head(null),
	];
	for (const pull of others) {
		const { outputs, comments } = await run({ permission: "read", user: AUTHOR, pull });
		assert.deepEqual(outputs, { proceed: "false" });
		assert.deepEqual(comments, []);
	}
	// they're allowed if they do have write access
	assert.equal((await run({ user: AUTHOR, pull: head(ORG_REPO) })).outputs.proceed, "true");
	// even if they personally own the main repository, this isn't a fork
	const owned = { ...ORG_REPO, owner: { id: AUTHOR.id } };
	assert.equal(isOwnFork(makePull({ head: { repo: owned }, base: { repo: owned } }), AUTHOR), false);
});

test("reusing an author's old name doesn't work", async () => {
	const { outputs } = await run({ permission: "read", user: { id: 99, login: "author" } });
	assert.deepEqual(outputs, { proceed: "false" });
});

test("other comments are ignored", async () => {
	const { outputs } = await run({ body: "nice sprites" });
	assert.deepEqual(outputs, { proceed: "false" });
});

test("blocked pull requests are explained", async () => {
	const { outputs, comments } = await run({ pull: makePull({ maintainer_can_modify: false }) });
	assert.deepEqual(outputs, { proceed: "false" });
	assert.match(comments[0], /Allow edits by maintainers/);
});

test("blockers", () => {
	const own = { sha: "abc", ref: "feature", repo: ORG_REPO };
	assert.equal(getBlocker(makePull(), "master"), null);
	assert.equal(getBlocker(makePull({ head: own, maintainer_can_modify: false }), "master"), null);
	assert.match(getBlocker(makePull({ head: { ...own, ref: "master" } }), "master"), /Refusing/);
	assert.match(getBlocker(makePull({ state: "closed" }), "master"), /not open/);
	assert.match(getBlocker(makePull({ head: { ...own, repo: null } }), "master"), /no longer exists/);
	// a fork's own master branch is fine
	assert.equal(getBlocker(makePull({ head: { ...makePull().head, ref: "master" } }), "master"), null);
});

test("untrusted text can't escape from a code block", () => {
	const result = codeBlock("a\n```\n@everyone");
	assert.equal(result, "```text\na\n'''\n@everyone\n```");
	assert.ok(codeBlock("x".repeat(100000)).length < 21000);
});

test("comments", () => {
	const base = { pushed: false, report: "", conflicts: "", runUrl: "https://run" };
	assert.match(buildComment({ ...base, status: "clean" }), /no conflicts/);
	assert.match(buildComment({ ...base, status: "unrelated", conflicts: "a.dm" }), /by hand.*a\.dm/s);
	assert.match(buildComment({ ...base, status: "conflict", conflicts: "a.dmi", report: "log" }), /a\.dmi.*log/s);
	assert.match(buildComment({ ...base, status: "resolved", pushed: true }), /^Resolved/);
	assert.match(buildComment({ ...base, status: "resolved" }), /couldn't be pushed/);
	assert.match(buildComment({ ...base, status: "" }), /went wrong.*https:\/\/run/);
});
