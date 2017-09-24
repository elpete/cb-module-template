# A CommandBox tool for scaffolding ForgeBox modules
[![All Contributors](https://img.shields.io/badge/all_contributors-2-orange.svg?style=flat-square)](#contributors)

<a target='_blank' rel='nofollow' href='https://app.codesponsor.io/link/TQMfPZtDP7SHs7UgJVGg61uH/elpete/cb-module-template'>
  <img alt='Sponsor' width='888' height='68' src='https://app.codesponsor.io/embed/TQMfPZtDP7SHs7UgJVGg61uH/elpete/cb-module-template.svg' />
</a>

### Usage

Quickly create a ColdBox module that is ready to go with

1. `box.json` and `ModuleConfig.cfc` values set
2. Unit Testing
3. Integration Testing with a built-in ColdBox app
4. Publishing to ForgeBox with one command! (`bump --major`)
5. Automatic Travis-CI integration to run your tests on 5 different CF engine/versions with pass/fail badge on your readme.

```bash
box module scaffold myCoolModule "Short Module Description"
```

### Requirements

The **GitHub** integration assumes you have a GitHub account already.  The command will ask you for your GitHub username and password and will create an API token for you to publish your module.

The **Travis** integration requires no extra work.  It's just tied to your GitHub account.

**ForgeBox** publishing assumes you have a Forgebox.io account.  To create one, use the `forgebox register` command.

## Contributors

Thanks goes to these wonderful people ([emoji key](https://github.com/kentcdodds/all-contributors#emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
| [<img src="https://avatars1.githubusercontent.com/u/2583646?v=4" width="100px;"/><br /><sub>Eric Peterson</sub>](https://github.com/elpete)<br />[💻](https://github.com/elpete/cb-module-template/commits?author=elpete "Code") [📖](https://github.com/elpete/cb-module-template/commits?author=elpete "Documentation") [📢](#talk-elpete "Talks") | [<img src="https://avatars0.githubusercontent.com/u/584009?v=4" width="100px;"/><br /><sub>Brad Wood</sub>](http://www.codersrevolution.com)<br />[💻](https://github.com/elpete/cb-module-template/commits?author=bdw429s "Code") |
| :---: | :---: |
<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/kentcdodds/all-contributors) specification. Contributions of any kind welcome!