# Contribution Guidelines

This project welcomes contributions and suggestions. Most contributions require you to
agree to a Contributor License Agreement (CLA) declaring that you have the right to,
and actually do, grant us the rights to use your contribution. For details, visit
[https://cla.microsoft.com](https://cla.microsoft.com).

When you submit a pull request, a CLA-bot will automatically determine whether you need
to provide a CLA and decorate the PR appropriately (e.g., label, comment). Simply follow the
instructions provided by the bot. You will only need to do this once across all repositories using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/)
or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

Contributions come in many forms: submitting issues, writing code, and participating in discussions or questions.

## Use of Third-party code

Third-party code must include the associated license in the [`NOTICE`](NOTICE) file.

## Contribution Process

### Summary

We follow a [Kanban](https://en.wikipedia.org/wiki/Kanban_(development)) process. A product owner is responsible defining and prioritizing work in the product backlog. Each item in the backlog is a self-contained piece of work, finished to production quality and merged to the main branch. Releases are monthly and prioritization is set within releases. New priorities come from our stakeholders and from information we gather while doing the technical work.

### Why Kanban

- Prioritization is dynamic: new priorities are discovered during each release and Kanban helps us quickly respond to changes.
- Team member capacity is variable: our development capacity changes within each release.
- Backlog items are self-contained: each item is a self-contained set of valuable changes that can be individually merged to the main branch.
- Experienced team: we have a strong, experienced team that is able to execute Kanban in a disciplined way.

### Values

- Openness: We welcome external input and collaboration with the community.
- Transparency: All planned work is in public GitHub issues. Code is open source.
- Empowerment: All team members make decisions on behalf of the product. Consultation with the rest of the team and the product owner is advised, but each team member decides what level of collaboration is required when making decisions about requirements, design, and architecture.
- Continuous improvement: We continuously examine our process and implement intentional improvements based on empirical evidence.
- Production quality: All code in the main branch is production quality. We assist each other through pair programming and pull request reviews.

### Roles

These roles demonstrate how we think about doing the work. A single person can operate with multiple roles. Roles can be part-time or full-time.

- Program manager: Responsible for the success of the product. Coordinates with external groups. Identifies product opportunities. Develops the product roadmap in collaboration with the rest of the team.
- Product Owner: Responsible for the product backlog, architecture, and releases. Sometimes delegates decisions about the backlog and architecture to other team members, and always consults the team on key decisions. Communicates with external groups in collaboration with the program manager.
- Team: Responsible for converting the product backlog into working code and documentation. Contributes to the product backlog, prioritization, architecture, and external communications.
- Champion: Responsible for external communications and coaching to other groups. Funnels quality feedback into the product backlog. Contributes code and documentation to the product.

### Artifacts

- Product backlog: The product backlog is defined using GitHub issues. Issue templates are in the repo for Issues (new development) and bugs. Backlog items (issues and bugs) are grouped into releases and prioritized within each release. See the [product owner process](#product-owner-process) for more details.
- Monthly releases: Each release is defined using a GitHub project. One release is finished each month. We plan major themes for each release, but the actual content of a finished release depends on what is accomplished using our Kanban process.
- Software increment: Each change to the software is implemented as a git commit to the main branch. GitHub pull requests are used to define and review each commit to main as a squashed merge (all changes combined into a single commit.) See the [development process](#development-process) for more details.

### Events

- Daily meeting: each day we meet to report what we did to move the project forward yesterday, what we plan to do the next day, and to identify any new impediments that must be removed.
- Pair programming: we sometimes choose to work together on programming tasks.
- Weekly backlog planning: the team meets for one hour each week to review changes to the backlog, review our current prioritization, and plan for future releases.
- Monthly release retrospectives: in support of continuous improvement, we meet after each release to collaboratively decide on changes to our process based on our experience with the previous release.

### Development Process

#### Select an Issue

Team members select issues to develop. More than one member can work on a single issue, and pair programming and other collaboration is encouraged. Generally, issues that have higher priority should be done before lower priority issues, but any issue may be selected from the backlog by any team member.

#### Create a Branch

Issues that require code or documentation changes should be developed on a branch. These are guidelines for branching (not strict requirements):

- The naming convention for branches is `<team member name or ID>/<one or two word description>`.
- Every day, branches should be reverse integrated with main and updated from work in progress on the development machine.
- Branches can be in a broken state.

#### Develop

Keep short dev/test/commit cycles within a branch, and create many commits per day. Keep the development branch in sync with main to avoid difficult merges. Stay in contact with teammates about what is changing so that merges do not conflict.

#### Submit a PR

Multiple PRs can be created for an issue, but there is usually a single pull request per issue. Optionally ask specific teammates for a review. Carefully follow the checklist in the PR template. Ensure that at least one GitHub issue is associated with the PR and assigned to the current release. When the PR is completed/closed, make sure the GitHub issue is also closed.

A draft PR can be used to request feedback from the team.

#### Review Other PRs

When PRs are requested, review each change and run full test deployment, specifically focused on the areas that have changed. Provide comments and feedback directly related to the PR.

#### Ensure Quality

The main branch is always production quality. The PR reviewer is responsible for ensuring that code merged to main meets our quality standards.

### Product Owner Process

#### Product Backlog

The backlog is defined in the form of GitHub issues, including bugs and regular issues. Any team member or external stakeholder can author a backlog item. The product owner is responsible for ensuring that all backlog items in a release meet the standards of being ready for development. The standards include:

- A clear title
- A concise benefit/result/outcome that defines the benefit someone would receive when the issue is completed.
- An optional tag that defines who will benefit from the issue being completed
- A detailed description that contains more context and may contain implementation details.
- A full list of acceptance criteria that clearly define when the issue is complete.
- Scope that is as small as possible and is also a complete and useful new feature for a stakeholder.

#### Triage

The product owner is responsible for ensuring that each issue is fully triaged and is either closed or added to a release backlog. Triage with the team primarily happens at the weekly planning meeting and can also happen via GitHub as comments within an issue.

When new issues are added to the GitHub issues list, the product owner makes sure that a `needs triage` label is added so that the issue will be discussed in the next planning meeting.

#### Release Definition

The product owner defines the releases in the form of GitHub projects. One release is defined per month. Each release has one or more themes. The themes are reviewed and agreed upon by the team during the weekly planning meeting.

#### Weekly Planning Meeting

The product owner sets the agenda for the meeting. The agenda includes:

- New issues that need triage, usually selected by GitHub issues with a `needs triage` label.
- Prioritization of new and existing issues within the current release. Items added or removed from the current release.
- Changes to the themes of the current and future releases, and the scope of future releases.
- Issues that are not currently in a release. (Filter the GitHub Issues list for issues not currently assigned to a project, i.e., `is:issue is:open no:project`).

#### Backlog Prioritization

The product owner is responsible for ensuring that the backlog items are prioritized within each release. Setting priority is a collaborative effort by the team. Priority is defined by the stack rank order of the "To do" column in a release.

#### Architecture

The product owner is responsible for ensuring that enough architecture documentation exists for the development team and stakeholders. Developing the architecture is a collaborative effort with the rest of the team. Any team member may contribute to the architecture, and some issues may be added to the backlog for discovery and testing in order to determine the elements of the architecture.

**Thank You!** - Your contributions to open source, large or small, make projects like this possible. Thank you for taking the time to contribute.
