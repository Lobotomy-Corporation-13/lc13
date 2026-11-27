const COMMAND = "/resolve-dmi";
const MAX_LOG_LENGTH = 20000;

export const isCommand = (body) => (body || "").trim() === COMMAND;

/**
 * File names and icon state names are controlled by whoever made the PR.
 * Inside of a code block the only thing they could do is close it.
 */
export function codeBlock(text) {
	let safe = text.replace(/`/g, "'").trim();
	if (safe.length > MAX_LOG_LENGTH) {
		safe = safe.slice(0, MAX_LOG_LENGTH) + "\n... (truncated)";
	}
	return "```text\n" + safe + "\n```";
}

/**
 * Returns the reason that a PR can't be pushed to, or null if there isn't one.
 */
export function getBlocker(pull, defaultBranch) {
	if (pull.state !== "open") {
		return "This pull request is not open.";
	}
	if (!pull.head.repo) {
		return "The repository this pull request was made from no longer exists.";
	}
	if (pull.head.repo.full_name !== pull.base.repo.full_name) {
		if (!pull.maintainer_can_modify) {
			return 'The author needs to enable "Allow edits by maintainers" on this pull request first.';
		}
	} else if (pull.head.ref === defaultBranch) {
		return `Refusing to push to \`${defaultBranch}\`.`;
	}
	return null;
}

/**
 * Authors can use this on PRs from their own fork, where they could push anyway.
 * This compares IDs because logins can be changed and then reused.
 */
export function isOwnFork(pull, user) {
	return (
		pull.user.id === user.id
		&& !!pull.head.repo
		&& pull.head.repo.owner.id === user.id
		&& pull.head.repo.id !== pull.base.repo.id
	);
}

/**
 * Checks if the commenter is allowed to do this, and if the PR can be pushed to.
 * Sets the outputs that are needed by the other jobs.
 */
export async function authorize({ github, context, core }) {
	const { owner, repo } = context.repo;
	const { comment, issue, repository } = context.payload;
	core.setOutput("proceed", "false");

	if (!isCommand(comment.body)) {
		console.log("not a command");
		return;
	}

	const { data: pull } = await github.rest.pulls.get({
		owner,
		repo,
		pull_number: issue.number,
	});

	if (!isOwnFork(pull, comment.user)) {
		// The comment's author_association doesn't say if they have write access
		const { data: access } = await github.rest.repos.getCollaboratorPermissionLevel({
			owner,
			repo,
			username: comment.user.login,
		});
		if (access.permission !== "admin" && access.permission !== "write") {
			console.log(`${comment.user.login} only has ${access.permission} permission`);
			return;
		}
	}

	const blocker = getBlocker(pull, repository.default_branch);
	if (blocker) {
		await github.rest.issues.createComment({
			owner,
			repo,
			issue_number: issue.number,
			body: `Can't resolve icon conflicts. ${blocker}`,
		});
		return;
	}

	await github.rest.reactions.createForIssueComment({
		owner,
		repo,
		comment_id: comment.id,
		content: "eyes",
	});

	core.setOutput("head_sha", pull.head.sha);
	core.setOutput("head_ref", pull.head.ref);
	core.setOutput("head_repo", pull.head.repo.full_name);
	core.setOutput("base_ref", pull.base.ref);
	core.setOutput("proceed", "true");
}

export function buildComment({ status, pushed, report, conflicts, runUrl }) {
	const details = report.trim()
		? `\n\n<details><summary>Merge log</summary>\n\n${codeBlock(report)}\n\n</details>`
		: "";
	const list = conflicts.trim() ? `\n\n${codeBlock(conflicts)}` : "";
	const local = "merge the base branch locally, after running `tools/hooks/Install.bat`";

	switch (status) {
		case "clean":
			return "This pull request has no conflicts, so there is nothing to resolve.";
		case "unrelated":
			return `None of the conflicts are in icons, so nothing was changed. These need to be resolved by hand:${list}`;
		case "conflict":
			return `Some conflicts couldn't be resolved automatically, so nothing was changed. To resolve these, ${local}:${list}${details}`;
		case "resolved":
			if (pushed) {
				return `Resolved the icon conflicts. Check the icon diff before merging.${details}`;
			}
			return (
				"The icon conflicts can be resolved automatically, but the result couldn't be pushed. "
				+ "The branch may have changed, or the bot may not have permission to push to it. "
				+ `Try again, or ${local}. See the [workflow run](${runUrl}).${details}`
			);
		default:
			return `Something went wrong while resolving icon conflicts. See the [workflow run](${runUrl}).`;
	}
}

export async function postResult({ github, context, status, pushed, report, conflicts }) {
	const { owner, repo } = context.repo;
	await github.rest.issues.createComment({
		owner,
		repo,
		issue_number: context.payload.issue.number,
		body: buildComment({
			status,
			pushed,
			report,
			conflicts,
			runUrl: `${context.serverUrl}/${owner}/${repo}/actions/runs/${context.runId}`,
		}),
	});
}
