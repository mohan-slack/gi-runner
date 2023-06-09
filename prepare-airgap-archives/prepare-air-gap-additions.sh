#!/bin/bash
set -e
trap "exit 1" ERR

source scripts/init.globals.sh
source scripts/shared_functions.sh

get_pre_scripts_variables
pre_scripts_init

setup_local_registry
msg "Mirroring openldap container" true
images="docker.io/bitnami/openldap:latest"
for image in $images
do
	echo $image
        podman pull $image
	check_exit_code $? "Cannot pull image $image"
        tag=`echo "$image" | awk -F '/' '{print $NF}'`
        echo "TAG: $tag"
	podman push --creds admin:guardium $image ${host_fqdn}:5000/adds/$tag
	podman rmi $image
done
msg "Extracting image digests ..." true
echo "openldap:latest,"`cat /opt/registry/data/docker/registry/v2/repositories/adds/openldap/_manifests/tags/latest/current/link` > ${air_dir}/digests.txt
echo "Archiving mirrored registry ..."
podman stop bastion-registry
cd /opt/registry
tar cf ${air_dir}/additions-registry-`date +%Y-%m-%d`.tar data
cd ${air_dir}
tar -rf ${air_dir}/additions-registry-`date +%Y-%m-%d`.tar digests.txt
rm -f digests.txt
podman rm bastion-registry
podman rmi --all
rm -rf /opt/registry/data
rm -rf $GI_TEMP
msg "Images with additonal services prepared - copy file ${air_dir}/addition-registry-`date +%Y-%m-%d`.tar to air-gapped bastion machine" true
