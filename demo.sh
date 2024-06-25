#!/usr/bin/env bash

# Load helper functions and set initial variables
vendir sync
. ./vendir/demo-magic/demo-magic.sh

export TYPE_SPEED=100
export DEMO_PROMPT="${GREEN}➜ ${CYAN}\W ${COLOR_RESET}"
JAVA_21="23.1.3.r21-nik"
JAVA_8="8.0.412-librca"
TEMP_DIR="upgrade-example"
PROMPT_TIMEOUT=5

# Function to pause and clear the screen
function talkingPoint() {
  wait
  clear
}

# Initialize SDKMAN and install required Java versions
function initSDKman() {
  local sdkman_init="${SDKMAN_DIR:-$HOME/.sdkman}/bin/sdkman-init.sh"
  if [[ -f "$sdkman_init" ]]; then
    source "$sdkman_init"
  else
    echo "SDKMAN not found. Please install SDKMAN first."
    exit 1
  fi
  sdk update
  sdk install java "$JAVA_8"
  sdk install java "$JAVA_21"
}

# Prepare the working directory
function init {
  rm -rf "$TEMP_DIR"
  mkdir "$TEMP_DIR"
  cd "$TEMP_DIR" || exit
  clear
}

# Switch to a specified Java version and display the version
function useJava() {
  local java_version=$1
  local message=$2
  displayMessage "$message"
  pei "sdk use java $java_version"
  pei "java -version"
}

# Clone a Spring Boot application
function cloneApp {
  displayMessage "Clone a Spring Boot 2.6.0 application"
  pei "git clone https://github.com/dashaun/hello-spring-boot-2-6.git ./"
}

# Start the Spring Boot application and log the output
function springBootStart {
  local log_file=$1
  displayMessage "Start the Spring Boot application"
  pei "./mvnw -q clean package spring-boot:start -DskipTests 2>&1 | tee '$log_file' &"
}

# Stop the Spring Boot application
function springBootStop {
  displayMessage "Stop the Spring Boot application"
  pei "./mvnw spring-boot:stop -Dspring-boot.stop.fork"
}

# Check the health of the application
function validateApp {
  displayMessage "Check application health"
  pei "http :8080/actuator/health"
}

# Display memory usage of the application
function showMemoryUsage {
  local pid=$1
  local log_file=$2
  local rss=$(ps -o rss= "$pid" | tail -n1)
  local mem_usage=$(bc <<< "scale=1; ${rss}/1024")
  echo "The process was using ${mem_usage} megabytes"
  echo "${mem_usage}" >> "$log_file"
}

# Upgrade the application to Spring Boot 3.3
function rewriteApplication {
  displayMessage "Upgrade to Spring Boot 3.3 using OpenRewrite"
  pei "./mvnw -U org.openrewrite.maven:rewrite-maven-plugin:run \
      -Drewrite.recipeArtifactCoordinates=org.openrewrite.recipe:rewrite-spring:LATEST \
      -Drewrite.activeRecipes=org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_3"
}

# Build a native image of the application
function buildNative {
  displayMessage "Build a native image with AOT"
  pei "./mvnw -Pnative native:compile"
}

# Start the native image
function startNative {
  displayMessage "Start the native image"
  pei "./target/hello-spring 2>&1 | tee nativeWith3.3.log &"
}

# Stop the native image
function stopNative {
  displayMessage "Stop the native image"
  local npid=$(pgrep hello-spring)
  pei "kill -9 $npid"
}

# Display a message with a header
function displayMessage() {
  echo "#### $1"
  echo ""
}

# Extract startup time from log file
function startupTime() {
  local log_file=$1
  echo "$(sed -nE 's/.* in ([0-9]+\.[0-9]+) seconds.*/\1/p' < "$log_file")"
}

# Display a table comparing memory usage and startup times
function statsSoFarTable {
  displayMessage "Comparison of memory usage and startup times"
  echo ""
  
  # Headers
  printf "%-35s %-25s %-15s %s\n" "Configuration" "Startup Time (seconds)" "(MB) Used" "(MB) Savings"
  echo "--------------------------------------------------------------------------------------------"

  # Spring Boot 2.6 with Java 8
  MEM1=$(cat java8with2.6.log2)
  printf "%-35s %-25s %-15s %s\n" "Spring Boot 2.6 with Java 8" "$(startupTime 'java8with2.6.log')" "$MEM1" "-"

  # Spring Boot 3.3 with Java 21
  MEM2=$(cat java21with3.3.log2)
  PERC2=$(bc <<< "scale=2; 100 - ${MEM2}/${MEM1}*100")
  printf "%-35s %-25s %-15s %s\n" "Spring Boot 3.3 with Java 21" "$(startupTime 'java21with3.3.log')" "$MEM2" "$PERC2%"

  # Spring Boot 3.3 with AOT processing, native image
  MEM3=$(cat nativeWith3.3.log2)
  PERC3=$(bc <<< "scale=2; 100 - ${MEM3}/${MEM1}*100")
  printf "%-35s %-25s %-15s %s\n" "Spring Boot 3.3 with AOT, native" "$(startupTime 'nativeWith3.3.log')" "$MEM3" "$PERC3%"
}

function cfStats {
  bash ../stats.sh
}

# Cloud Foundry push for non-native app
function cfPush {
  local manifest_file=$1
  pei "cf push -f ../$manifest_file > /dev/null 2>&1 &"
}

# Cloud Foundry push for native app
function cfPushNative {
  pei "cd ../prebaked"
  pei "cf push -f manifest-native.yml > /dev/null 2>&1 &"
  pei "cd ../$TEMP_DIR"
}

# Main execution flow
initSDKman
init

# Use Java 8 and perform operations
useJava "$JAVA_8" "Use Java 8 for educational purposes"
talkingPoint
cloneApp
talkingPoint
springBootStart "java8with2.6.log"
talkingPoint
validateApp
talkingPoint
showMemoryUsage "$(jps | grep 'HelloSpringApplication' | cut -d ' ' -f 1)" "java8with2.6.log2"
talkingPoint
springBootStop
talkingPoint
cfPush "manifest-java8.yml"
talkingPoint

# Upgrade to Java 21 and perform operations
rewriteApplication
talkingPoint
useJava "$JAVA_21" "Switch to Java 21 for Spring Boot 3"
talkingPoint
springBootStart "java21with3.3.log"
talkingPoint
validateApp
talkingPoint
showMemoryUsage "$(jps | grep 'HelloSpringApplication' | cut -d ' ' -f 1)" "java21with3.3.log2"
talkingPoint
springBootStop
talkingPoint
cfPush "manifest-java21.yml"
talkingPoint

# Build and run native image
buildNative
talkingPoint
startNative
talkingPoint
validateApp
talkingPoint
showMemoryUsage "$(pgrep hello-spring)" "nativeWith3.3.log2"
talkingPoint
stopNative
talkingPoint
cfPushNative
talkingPoint

# Display stats and images
statsSoFarTable
cfStats