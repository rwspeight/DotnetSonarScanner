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
::      [C# project path (default:$projectPathDefault)] \\ 
::      [Comma separated list of NuGet source (default:"")] \\
::      [SonarQube server URL (default:$sonarUrlDefault)]
::
END
)

# Required params
sonarProjectKey=${1:?"$syntax"}
sonarOrg=${2:?"$syntax"}
sonarToken=${3:?"$syntax"}

# Optional params
projectPath=${4:-"$projectPathDefault"}
nugetSources=${5:-""}
sonarUrl=${6:-"$sonarUrlDefault"}

# Variables
coveragePath="/tmp/opencover.xml"
sourcesParams=$(awk -F, '{for(i=1; i <= NF; ++i) { printf "--source %s ", $i }}' <<<$nugetSources)

# Pull out comma separarte list of test libraries.
# Expected format: ^TestLibrary=libName1,libName2,...,libName#
testLibraries=$(awk -F= '/^TestLibraries/{print $2}' .dotnet-sonarcloud-scanner | sed 's:,: :g')

if [ -z "$testLibraries" ]; then
  echo "A comma separate list of unit test library names must be present in [project root]/.dotnet-sonarcloud-scanner"
  echo "Expected format:  TestLibraries=testLib1,testLib2,...,testLib#"
  echo "NOTE:  Only the first test project will be run as there is an outstanding issue"
  echo "merging multiple coverage reports in opencover format.  This will be fixed in the future."
  exit 1
fi

dotnet-sonarscanner begin  \
  -d:sonar.host.url=$sonarUrl \
  -key:$sonarProjectKey \
  -o:$sonarOrg \
  -d:sonar.login=$sonarToken \
  -d:sonar.cs.opencover.reportsPaths=$coveragePath

dotnet restore \
  $projectPath \
  $sourcesParams

dotnet build \
  -c Release $projectPath \
  -o /tmp/build

for test in $testLibraries
do
  # Run the tests but throw away the exit code using `... || true`
  # so the errexit setting doesn't bail out on the non-zero code
  coverlet \
    /tmp/build/$test \
    --target "dotnet" \
    --targetargs "test /tmp/build/$test" \
    --output $coveragePath \
    --format opencover \
    || true

  # Only process the first library to avoid the current issue merging
  # multiple coverage files in opencover format
  break
done

dotnet-sonarscanner end  \
  -d:sonar.login=$sonarToken