# DotnetSonarScanner
Container for performing C# code analysis with SonarQube's dotnet-sonarscanner command and coverlet for coverage reporting.  Container based on MS's .NET SDK. 

## Assumptions
- Repo file structure
    - Test projects are assumed to reside under a single parent directory and not be spread across various sibling folders.  As an example...
        - Examples
            - Good
                {Project Root}
                    - A
                        - B
                            - Test1
                            - Test2
            - Bad
                {Project Root}
                    - A
                        - B
                            - Test1
                            - Test2
                        - C
                            - Test3
                            - Test4
        
## Versions
| Tool | Version |
|-|-|
| Coverlet.Console | 1.7.1 |
| SonarScanner | 4.9.0 |

## Config Files
Copy the `example.dotnet-sonarcloud-scanner` to `.dotnet-sonarcloud-scanner` and set appropriate values.


## Resources
- [Coverlet Quick Start](https://github.com/coverlet-coverage/coverlet#Quick-Start)
- [Coverlet for MSBuild](https://github.com/coverlet-coverage/coverlet/blob/master/Documentation/MSBuildIntegration.md)