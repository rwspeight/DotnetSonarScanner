FROM mcr.microsoft.com/dotnet/core/sdk:2.2

WORKDIR /project

COPY scan.sh /usr/local/bin/scan.sh

ENV ToolPath=/usr/local/bin
ENV CoverletMsbuildVersion=2.8.1
ENV SonarScannerVersion=4.9.0

# Install Java needed by SonarScanner.  Java 11 is required by SonarCloud
# but does not currently have a direct package for Debian 9.  The Internets
# say to use the backports feed.
RUN echo 'deb http://ftp.debian.org/debian stretch-backports main' \
  | sudo tee /etc/apt/sources.list.d/stretch-backports.list
RUN apt-get update
RUN apt-get install -y openjdk-11-jdk-headless

# Force a global cache of the coverlet.msbuild NuGet
# package to prevent later download
RUN cd /tmp \
  && dotnet new xunit \
  && dotnet add package coverlet.msbuild \
    --version $CoverletMsbuildVersion

# Install SonarScanner for code analysis
RUN dotnet tool install \
  --tool-path $ToolPath \
  --version $SonarScannerVersion \
  dotnet-sonarscanner 

ENTRYPOINT ["bash"]
