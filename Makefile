
PACKAGE_NAME=simple-rna-seq
MAIN_NF_FILE="main.nf"

SERVICE_ID=urn:ivcap:service:a98b81a8-9279-509f-9c0e-40d39e83058a

run: clean-local
	nextflow run ${MAIN_NF_FILE} \
		-c nextflow.config \
		-c conf/weblog.disabled.config \
		-params-file params.json \
		--input data/paired-end.csv \
		-cache false

mermaid:
	nextflow run ${MAIN_NF_FILE} \
		-c nextflow.config \
		-c conf/weblog.disabled.config \
		-params-file params.json \
  	-preview -with-dag flowchart.mmd

TEST_REQUEST=tests/simple_rnaseq_ivcap.json
test-job: IVCAP_API=https://develop.ivcap.net
test-job:
	ivcap job create ${SERVICE_ID} -f ${TEST_REQUEST} --stream

deploy: deploy-service

deploy-service: deploy-pipeline
	@cat ivcap-service.yaml | \
		sed 's/@SERVICE_ID@/${SERVICE_ID}/g' | \
		sed 's/@PIPELINE@/$(shell ivcap --silent artifact create -n "${PACKAGE_NAME} nextflow pipeline" -p urn:ivcap:policy:ivcap.open.artifact -f ${PACKAGE_NAME}.tar)/g' | \
		ivcap df update ${SERVICE_ID} -p urn:ivcap:policy:ivcap.open.metadata --format yaml -f -

deploy-pipeline: package
	ivcap artifact create -n "${PACKAGE_NAME} nextflow pipeline" -p urn:ivcap:policy:ivcap.open.artifact -f ${PACKAGE_NAME}.tar

package: ${PACKAGE_NAME}.tar

${PACKAGE_NAME}.tar:
	tar cvf ${PACKAGE_NAME}.tar ${MAIN_NF_FILE} nextflow.config modules/ conf/ schema_input.json

clean: clean-local
	rm -rf ${PACKAGE_NAME}.tar

clean-local:
	rm -rf .nextflow* work results