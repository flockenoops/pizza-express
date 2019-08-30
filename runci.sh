#!/bin/bash

TEST_COMPOSE="./docker-compose.test.yml"
APP_COMPOSE="./docker-compose.yml"
TEST_CONTAINER_NAME="pizzaexpress_test"
APP_CONTAINER_NAME="pizzaexpress_app"
DOCKER_REPO=YOUR_REPO_HERE
APP_NAME_TO_PUSH="pizzaexpress_app"
PUSH_TAG="latest"

buildTests (){
  log "Building tests"
  docker-compose -f $TEST_COMPOSE build
  if [ $? != 0 ]
  then
    log "Could not build test images"
    return 1
  else
    log "Built test images successfully"
    return 0
  fi
}

runTests (){
  log "Running tests"
  docker-compose -f $TEST_COMPOSE up -d
  if [ $? != 0 ]
  then
    log "Failed to run tests!"
    return 1
  fi
  local RESULT=`docker wait $TEST_CONTAINER_NAME`
  local LOG=`docker logs $TEST_CONTAINER_NAME`
  if [ $? != 0 ]
  then
    log "One or more of the tests failed! Logs below:"
    log $LOG
	return 1
  else
    log "All tests passed successfully! Logs below:"
	log $LOG
  fi
}

buildApp (){
  log "Building app"
  docker-compose -f $APP_COMPOSE build
  if [ $? != 0 ]
  then
    log "Failed to build app images!"
	return 1
  else
    log "Finished building app"
  fi
}

testApp (){
  log "Starting app for sanity"
  docker-compose -f $APP_COMPOSE up -d
  log "Running test"
  local response=$(curl --write-out %{http_code} --silent --output /dev/null localhost:8081)
  if [ "$response" != "200" ]
  then
    log "Something went wrong! HTTP code: $response"
	return 1
  else
    log "The application responds with HTTP code $response"
  fi
}

pushApp (){
  log "Pushing app to DockerHub"
  local LATEST_IMAGE=$(docker images pizzaexpress_app:latest -q)
  docker tag $LATEST_IMAGE $DOCKER_REPO/$APP_NAME_TO_PUSH:$PUSH_TAG
  docker push $DOCKER_REPO/$APP_NAME_TO_PUSH
  if [ $? != 0 ]
  then
    log "Failed to push to remote repository!"
	return 1
  else
    log "App successfully pushed"
  fi
}

log ()
{
  echo
  echo "`date '+%b %e %H:%M:%S'`: $1"
  echo
}

buildTests && runTests && buildApp && testApp && pushApp
