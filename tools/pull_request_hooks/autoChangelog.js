import { parseChangelog } from "./changelogParser.js";

const safeYml = (string) =>
	string.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\n/g, "\\n");

export function changelogToYml(changelog, login) {
	const author = changelog.author || login;
	const ymlLines = [];

	ymlLines.push(`author: "${safeYml(author)}"`);
	ymlLines.push(`delete-after: True`);
	ymlLines.push(`changes:`);

	for (const change of changelog.changes) {
		ymlLines.push(
			`  - ${change.type.changelogKey}: "${safeYml(change.description)}"`
		);
	}

	return ymlLines.join("\n");
}

export async function processAutoChangelog({ github, context }) {
	let changelog, userlogin, commitnumber, commitstring
	switch (context.eventName) {
		case "pull_request":
			changelog = parseChangelog(context.payload.pull_request.body)
			userlogin = context.payload.pull_request.user.login
			commitnumber = `pr-${context.payload.pull_request.number}`
			commitstring = `PR #${context.payload.pull_request.number}`
			break;
		case "push":
			changelog = parseChangelog(context.payload.head_commit.message)
			userlogin = context.payload.head_commit.author.username
			commitnumber = `commit-${context.sha}`
			commitstring = `Commit SHA${context.sha}`
			break;
		default:
			console.log("unsupported event type")
			return;
	}

	if (!changelog || changelog.changes.length === 0) {
		console.log("no changelog found");
		return;
	}

	const yml = changelogToYml(
		changelog,
		userlogin
	);

	github.rest.repos.createOrUpdateFileContents({
		owner: context.repo.owner,
		repo: context.repo.repo,
		path: `html/changelogs/AutoChangeLog-${commitnumber}.yml`,
		message: `Automatic changelog for ${commitstring} [ci skip]`,
		content: Buffer.from(yml).toString("base64"),
	});
}
