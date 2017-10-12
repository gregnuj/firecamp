#!/bin/sh
set -x
set -e

export TOPWD="$(pwd)"

version=$1
buildtarget=$2

org="cloudstax/"
system="firecamp"

BuildPlugin() {
  path="${TOPWD}/scripts/plugin-dockerfile"
  target="$system-pluginbuild"
  image="${org}${target}"

  echo "### docker build: builder image"
	docker build -q -t $image $path

	echo "### docker run: builder image with source code dir mounted"
  containername="$system-buildtest"
  docker rm $containername || true
  # the build container not exist, create and run it
  docker run --name $containername -v ${TOPWD}:/go/src/github.com/cloudstax/firecamp $image

  # build the volume plugin
  volumePluginPath="${TOPWD}/syssvc/firecamp-dockervolume/dockerfile"
  volumePluginImage="${org}$system-volume"
	echo "### docker build: rootfs image with firecamp-dockervolume"
	docker cp $containername:/go/bin/firecamp-dockervolume $volumePluginPath
	docker build -q -t ${volumePluginImage}:rootfs $volumePluginPath
  rm -f $volumePluginPath/firecamp-dockervolume

  echo "### create the plugin rootfs directory"
  volumePluginBuildPath="${TOPWD}/build/volumeplugin"
	mkdir -p $volumePluginBuildPath/rootfs
  docker rm -vf tmp || true
	docker create --name tmp ${volumePluginImage}:rootfs
	docker export tmp | tar -x -C $volumePluginBuildPath/rootfs
	cp ${TOPWD}/syssvc/firecamp-dockervolume/config.json $volumePluginBuildPath
	docker rm -vf tmp

	echo "### create new plugin ${volumePluginImage}:${version}"
	docker plugin rm -f ${volumePluginImage}:${version} || true
	docker plugin create ${volumePluginImage}:${version} $volumePluginBuildPath
	docker plugin push ${volumePluginImage}:${version}


  # build the log plugin
  logPluginPath="${TOPWD}/syssvc/firecamp-dockerlogs/dockerfile"
  logPluginImage="${org}$system-log"
	echo "### docker build: rootfs image with firecamp-dockerlogs"
	docker cp $containername:/go/bin/firecamp-dockerlogs $logPluginPath
	docker build -q -t ${logPluginImage}:rootfs $logPluginPath
  rm -f $logPluginPath/firecamp-dockerlogs

  echo "### create the plugin rootfs directory"
  logPluginBuildPath="${TOPWD}/build/logplugin"
	mkdir -p $logPluginBuildPath/rootfs
  docker rm -vf tmp || true
	docker create --name tmp ${logPluginImage}:rootfs
	docker export tmp | tar -x -C $logPluginBuildPath/rootfs
	cp ${TOPWD}/syssvc/firecamp-dockerlogs/config.json $logPluginBuildPath
	docker rm -vf tmp

	echo "### create new plugin ${logPluginImage}:${version}"
	docker plugin rm -f ${logPluginImage}:${version} || true
	docker plugin create ${logPluginImage}:${version} $logPluginBuildPath
	docker plugin push ${logPluginImage}:${version}
}


BuildCatalogImages() {
  # build test busybox docker image
  echo
  echo "build test busybox image for ecs and swarm unit test"
  target="${system}-busybox"
  image="${org}${target}:${version}"
  path="${TOPWD}/containersvc/busybox-test-dockerfile/"
  docker build -q -t $image $path
  docker push $image

  # build manageserver docker image
  echo
  target=$system"-manageserver"
  image="${org}${target}:${version}"
  binfile=$target
  path="${TOPWD}/syssvc/firecamp-manageserver/dockerfile/"
  cp $GOPATH/bin/$binfile $path
  docker build -q -t $image $path
  rm -f $path$binfile
  docker push $image


  # build controldb docker image
  echo
  target=$system"-controldb"
  image="${org}${target}:${version}"
  binfile=$target
  path="${TOPWD}/syssvc/firecamp-controldb/dockerfile/"
  cp $GOPATH/bin/$binfile $path
  docker build -q -t $image $path
  rm -f $path$binfile
  docker push $image
  echo


  # build mongodb docker image
  target=$system"-mongodb"
  image="${org}${target}:${version}"
  path="${TOPWD}/catalog/mongodb/3.4/dockerfile/"
  docker build -q -t $image $path
  docker push $image

  echo
  target=$system"-mongodb-init"
  image="${org}${target}:${version}"
  path="${TOPWD}/catalog/mongodb/3.4/init-task-dockerfile/"
  cp ${TOPWD}/catalog/waitdns.sh ${path}
  docker build -q -t $image $path
  rm -f ${path}/waitdns.sh
  docker push $image


  # build postgres docker image
  echo
  target=$system"-postgres"
  image="${org}${target}:${version}"
  path="${TOPWD}/catalog/postgres/9.6/dockerfile/"
  cp ${TOPWD}/catalog/waitdns.sh ${path}
  docker build -q -t $image $path
  rm -f ${path}/waitdns.sh
  docker push $image


  # build cassandra docker image
  echo
  target=$system"-cassandra"
  image="${org}${target}:${version}"
  path="${TOPWD}/catalog/cassandra/3.11/dockerfile/"
  docker build -q -t $image $path
  docker push $image

  echo
  target=$system"-cassandra-init"
  image="${org}${target}:${version}"
  path="${TOPWD}/catalog/cassandra/3.11/init-task-dockerfile/"
  cp ${TOPWD}/catalog/waitdns.sh ${path}
  docker build -q -t $image $path
  rm -f ${path}/waitdns.sh
  docker push $image


  # build zookeeper docker image
  echo
  target=$system"-zookeeper"
  image="${org}${target}:${version}"
  path="${TOPWD}/catalog/zookeeper/3.4.10/dockerfile/"
  docker build -q -t $image $path
  docker push $image


  # build kafka docker image
  echo
  target=$system"-kafka"
  image="${org}${target}:${version}"
  path="${TOPWD}/catalog/kafka/0.11/dockerfile/"
  docker build -q -t $image $path
  docker push $image


  # build redis docker image
  echo
  target=$system"-redis"
  image="${org}${target}:${version}"
  path="${TOPWD}/catalog/redis/4.0.1/dockerfile/"
  cp ${TOPWD}/catalog/waitdns.sh ${path}
  docker build -q -t $image $path
  rm -f ${path}/waitdns.sh
  docker push $image

  echo
  target=$system"-redis-init"
  image="${org}${target}:${version}"
  path="${TOPWD}/catalog/redis/4.0.1/init-task-dockerfile/"
  cp ${TOPWD}/catalog/waitdns.sh ${path}
  docker build -q -t $image $path
  rm -f ${path}/waitdns.sh
  docker push $image


  # build couchdb docker image
  echo
  target=$system"-couchdb"
  image="${org}${target}:${version}"
  path="${TOPWD}/catalog/couchdb/2.1.0/dockerfile/"
  docker build -q -t $image $path
  docker push $image

  echo
  target=$system"-couchdb-init"
  image="${org}${target}:${version}"
  path="${TOPWD}/catalog/couchdb/2.1.0/init-task-dockerfile/"
  cp ${TOPWD}/catalog/waitdns.sh ${path}
  docker build -q -t $image $path
  rm -f ${path}/waitdns.sh
  docker push $image


  # build consul docker image
  echo
  target=$system"-consul"
  image="${org}${target}:${version}"
  path="${TOPWD}/catalog/consul/0.9.3/dockerfile/"
  docker build -q -t $image $path
  docker push $image


  # build elasticsearch docker image
  echo
  target=$system"-elasticsearch"
  image="${org}${target}:${version}"
  path="${TOPWD}/catalog/elasticsearch/5.6.3/dockerfile/"
  docker build -q -t $image $path
  docker push $image

}

if [ "$buildtarget" = "all" ]; then
  BuildPlugin
  BuildCatalogImages
elif [ "$buildtarget" = "plugin" ]; then
  BuildPlugin
elif [ "$buildtarget" = "catalogs" ]; then
  BuildCatalogImages
fi

