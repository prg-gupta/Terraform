#!/bin/bash

BUILD_SERVER="BUILD_servcer"
REPO_NAME=@option.repo_name@
BRANCH=@option.branch@
BUILD_VERSION=@option.build_version@
ECR_ARN="ECR ARN"

cd /var/lib/rundeck/scripts/micro-service-images

echo "create directoty-: "$BUILD_VERSION
mkdir $BUILD_VERSION

cd  $BUILD_VERSION

BUILD_URL=$BUILD_SERVER$REPO_NAME/$BRANCH/$BUILD_VERSION.tar.gz
echo $BUILD_URL


curl  "$BUILD_URL" | tar -xz 

if [ "$?" -ne 0 ]
then 	
    echo "Failed the download the build"
    cd ..
    rm -rf $BUILD_VERSION
    exit 1
fi


version=`jq '.version' package.json |  tr -d '"'`

echo  "building the image"
  
docker build -t $REPO_NAME .
if [ $? -ne 0 ]
then 	
    echo "failed to build docker iamge"
    cd ..
    rm -rf $BUILD_VERSION
    exit 1
fi
echo "deleting the folder"
cd ..
rm -rf $BUILD_VERSION
docker tag $REPO_NAME:latest $ECR_ARN/$REPO_NAME:v$version


$(aws ecr get-login --region ap-southeast-1  --profile pt-images-push | sed -e 's/-e none//g' )

docker push $ECR_ARN/$REPO_NAME:v$version

docker rmi -f $ECR_ARN/$REPO_NAME:v$version
docker rmi -f $REPO_NAME:latest
