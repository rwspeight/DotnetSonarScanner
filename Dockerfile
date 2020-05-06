FROM mcr.microsoft.com/dotnet/core/sdk:3.1

WORKDIR /project

ENV ToolPath=/usr/local/bin
ENV CoverletVersion=1.7.1
ENV SonarScannerVersion=4.9.0

# Install Java needed by SonarScanner
RUN apt-get update
RUN apt-get install -y default-jre

# Install Coverlet for unit coverage reporting
RUN dotnet tool install \
  --tool-path $ToolPath \
  --version $CoverletVersion \
  coverlet.console

# Install SonarScanner for code analysis
RUN dotnet tool install \
  --tool-path $ToolPath \
  --version $SonarScannerVersion \
  dotnet-sonarscanner 

ENTRYPOINT ["bash"]
