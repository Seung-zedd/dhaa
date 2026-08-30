# Third-Party Notices

DHAA evaluates interoperability with external agentic development harnesses and related projects.

Unless explicitly stated otherwise, these projects are **research, reference, or interoperability targets** and are not relicensed by DHAA. Their source code, trademarks, and other copyrighted materials remain subject to their respective licenses and ownership.

DHAA itself is licensed under the [MIT License](LICENSE).

## External Projects

| Project | License | Relationship to DHAA |
|---|---|---|
| [MoAI-ADK](https://github.com/modu-ai/moai-adk) | Apache License 2.0 | Current reference implementation and interoperability target |
| [Everything Claude Code (ECC)](https://github.com/affaan-m/ECC) | MIT License | Interoperability and harness-agnostic experiment target |
| [Oh My OpenAgent (OMO)](https://github.com/code-yeongyu/oh-my-openagent) | Sustainable Use License 1.0 | Interoperability and harness-agnostic experiment target |

## License Boundaries

DHAA does not, merely by testing or documenting interoperability with an external project, relicense that project's software under the MIT License.

Third-party code or other copyrighted material incorporated into DHAA, if any, remains subject to the applicable upstream license and copyright notices. Where required by an upstream license, additional notices or license texts must be preserved alongside the incorporated material.

In particular:

- **MoAI-ADK** materials are subject to the Apache License 2.0 where applicable.
- **Everything Claude Code (ECC)** materials are subject to its MIT License where applicable.
- **Oh My OpenAgent (OMO)** materials are subject to its Sustainable Use License 1.0 where applicable. That license includes restrictions on commercial use and redistribution; DHAA's interoperability experiments do not override those restrictions.

## Interoperability Policy

DHAA aims to keep its core architecture independent from any single domain, harness, or agent implementation. External projects should therefore be integrated through clearly defined boundaries rather than copied into the DHAA core whenever practical.

When an experiment requires incorporating third-party source code, prompts, templates, rules, or other copyrighted material, the applicable upstream license must be reviewed before that material is committed or redistributed.

---

This notice is informational and does not replace the license terms of any third-party project. Refer to each upstream project's license for the authoritative terms.