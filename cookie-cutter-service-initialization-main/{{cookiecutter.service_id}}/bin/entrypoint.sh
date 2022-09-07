#!/usr/bin/env bash

#Run App
#To enable heap and object allocation monitoring in DD add -Ddd.profiling.heap.enabled=true -Ddd.profiling.allocation.enabled=true
java -javaagent:./dd-java-agent.jar -Ddd.version=`cat VERSION` -Ddd.profiling.enabled=true -jar app.jar

