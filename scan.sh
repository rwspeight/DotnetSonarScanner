#!/bin/bash

set -o errexit
set -o nounset

# Parameter defaults
projectPathDefault="."
sonarUrlDefault="https://sonarcloud.io"

# Syntax help
syntax=$(cat<<END

::
:: Purpose
::    Analyzes a C# project using coverlet
::    and sonar-scanner and sends results to
::    SonarQube server (i.e. SonarCloud)
::
:: Syntax
::    $(basename $0) \\ 
::      [Sonar project key] \\ 
::      [Sonar organization] \\ 
::      [Sonar auth token] \\ 
::      [Unit test DLL path] \\ 
::      [C# project path (default:$projectPathDefault)] \\ 
::      [SonarQube server URL (default:$sonarUrlDefault)]
::
END
)

# Required params
sonarProjectKey=${1:?"$syntax"}
sonarOrg=${2:?"$syntax"}
sonarToken=${3:?"$syntax"}
unitTestDllPath=${4:?"$syntax"}

# Optional params
projectPath=${5:-"$projectPathDefault"}
sonarUrl=${6:-"$sonarUrlDefault"}

# Variables
coveragePath="/tmp/opencover.xml"

dotnet-sonarscanner begin  \
  -d:sonar.host.url=$sonarUrl \
  -key:$sonarProjectKey \
  -o:$sonarOrg \
  -d:sonar.login=$sonarToken \
  -d:sonar.cs.opencover.reportsPaths=$coveragePath

dotnet build -c Release $projectPath

coverlet \
  $unitTestDllPath \
  --target "dotnet" \
  --targetargs "test $unitTestDllPath --no-build" \
  -f opencover -o $coveragePath

dotnet-sonarscanner end  \
  -d:sonar.login=$sonarToken
