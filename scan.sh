#!/bin/bash

set -o errexit
set -o nounset

configFile="${PWD}/.dotnet-sonarcloud-scanner"

# Syntax help
syntax=$(cat<<END

::
:: Purpose
::    Analyzes a C# project using coverlet and sonar-scanner and sends results to
::    SonarQube server (i.e. SonarCloud)
::
:: Syntax
::    $(basename $0) \\ 
::      [Sonar auth token] \\ 
::      [Comma separated list of NuGet source (default:"")] \\ 
::
:: Note
::    The following configuration values are pulled from the .dotnet-sonarcloud-scanner file, 
::    within the working directory where $(basename $0) is run.
::
::    SonarQubeUrl=https://sonarcloud.io
::    SonarProjectKey=SomeKey
::    SonarOrganization=SomeOrgName
::    SourcePath=./src
::    TestProjects=Unit.Tests.A,Unit.Tests.B,Unit.Tests.C
::
END
)

############### Required Params ###############
sonarToken=${1:?"$syntax"}

# Pull out comma separarte list of test libraries.
# Expected format: ^TestLibrary=libName1,libName2,...,libName#
testProjects=$(awk -F= '/^TestProjects/{print $2}' $configFile | sed 's:,: :g')
if [ -z "$testProjects" ]; then
  echo "A comma separate list of unit test library names must be present in [project root]/.dotnet-sonarcloud-scanner"
  echo "Expected format:  TestProjects=testLib1,testLib2,...,testLib#"
  exit 0
fi

# Fetch the server URL
sonarUrl=$(awk -F= '/^SonarQubeUrl/{print $2}' $configFile)
if [ -z "$sonarUrl" ]; then
  echo "A SonarQube server URL must be present in [project root]/.dotnet-sonarcloud-scanner"
  echo "Expected format:  SonarQubeUrl=https://sonar.qube.server"
  exit 0
fi

# Fetch the project key
sonarProjectKey=$(awk -F= '/^SonarProjectKey/{print $2}' $configFile)
if [ -z "$sonarProjectKey" ]; then
  echo "A SonarQube project key must be present in [project root]/.dotnet-sonarcloud-scanner"
  echo "Expected format:  SonarProjectKey=somekey"
  exit 0
fi

# Fetch the organization
sonarOrg=$(awk -F= '/^SonarOrganization/{print $2}' $configFile)
if [ -z "$sonarOrg" ]; then
  echo "A SonarQube organization must be present in [project root]/.dotnet-sonarcloud-scanner"
  echo "Expected format:  SonarOrganization=someorg"
  exit 0
fi

# Fetch the relative path to the root of the source files where a SLN or csproj file exists
sourcePath=$(awk -F= '/^SourcePath/{print $2}' $configFile)
if [ -z "$sourcePath" ]; then
  echo "A path to the source files (Sln or CsProj file) relative to the repo root must be present in [project root]/.dotnet-sonarcloud-scanner"
  echo "Expected format:  SourcePath=./src"
  exit 0
fi

############### Optional Params ###############
nugetSources=${2:-""}
nugetSourceParams=$(awk -F, '{for(i=1; i <= NF; ++i) { printf "--source %s ", $i }}' <<<$nugetSources)

############### Variables ###############
coverageReportPath="/tmp/opencover.$$.xml"
tempCoverageReportPath="/tmp/coverage.$$.json"

############### Begin Execution ###############
dotnet-sonarscanner begin  \
  -d:sonar.host.url=$sonarUrl \
  -key:$sonarProjectKey \
  -o:$sonarOrg \
  -d:sonar.login=$sonarToken \
  -d:sonar.cs.opencover.reportsPaths=$coverageReportPath

dotnet restore \
  $sourcePath \
  $nugetSourceParams

dotnet build \
  -c Release $sourcePath

for test in $testProjects
do
  dotnet add ${sourcePath}/${test} \
    package coverlet.msbuild

  # Coverlet's merge feature only works with its native reporting
  # format.  To submit an opencover formatted report to SonarQube,
  # we have to output and merge all but the last report in Coverlet's
  # native format, and output the last report in opencover.
  isLastTest=$(sed -n "/${test}\$/=" <<< $testProjects)
  
  if [ -n "$isLastTest" ]; then
    format=opencover
    outputPath=$coverageReportPath
  else
    format=json
    outputPath=$tempCoverageReportPath
  fi

  # Run the tests but throw away the exit code using `... || true`
  # so the errexit setting doesn't bail out on the non-zero code
  #
  # NOTE:  The `dotnet test` command does not fail if the MergeWith
  # file does not exist, and using the same file as the MergeWith 
  # input and CoverletOutput seems to be fine (though this may
  # break if files are read in chunks and buffered.)
  dotnet test \
    -p:CollectCoverage=true \
    -p:MergeWith=$tempCoverageReportPath \
    -p:CoverletOutputFormat=$format \
    -p:CoverletOutput=$coverageReportPath \
    --no-build \
  || true
  
done

dotnet-sonarscanner end  \
  -d:sonar.login=$sonarToken