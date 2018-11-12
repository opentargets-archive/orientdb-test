#!/bin/sh

RAW_GENE=18.10_gene-data.json.gz
RAW_EFO=18.10_efo-data.json.gz
RAW_EXPRESSION=18.10_expression-data.json.gz
RAW_ASSOCS=18.10_association_data.json.gz

VERTEX_GENE=18.10_vertex-gene.csv.gz
VERTEX_EFO=18.10_vertex-efo.csv.gz
VERTEX_TISSUE=18.10_vertex-tissue.csv.gz
EDGE_GENE_EFO=18.10_edge-gene-efo.csv.gz
EDGE_GENE_TISSUE=18.10_edge-gene-tissue.csv.gz
EDGE_EFO_EFO=18.10_edge-efo-efo.csv.gz

GS_POC=gs://open-targets/pocs/poc-01/
GS_RELEASES=gs://open-targets-data-releases/18.10/

LOCAL_RAW_DIR=./data/raw/
LOCAL_PROCESSED_DIR=./data/processed/

# ------- ENSURE DIRS EXIST ------- 

mkdir -p $LOCAL_RAW_DIR
mkdir -p $LOCAL_PROCESSED_DIR

# ------- DOWNLOAD RAW FILES ------- 

echo "Downloading raw files..."
gsutil -m cp $GS_POC$RAW_GENE $LOCAL_RAW_DIR$RAW_GENE
gsutil -m cp $GS_POC$RAW_EFO $LOCAL_RAW_DIR$RAW_EFO
gsutil -m cp $GS_POC$RAW_EXPRESSION $LOCAL_RAW_DIR$RAW_EXPRESSION
gsutil -m cp $GS_RELEASES$RAW_ASSOCS $LOCAL_RAW_DIR$RAW_ASSOCS
echo "Downloaded raw files."

# ------- PREPARE VERTICES DATA -------

echo "Building loadable vertex files..."

echo "-- GENE"
gzcat $LOCAL_RAW_DIR$RAW_GENE | sed '1s/^/[/; $!s/$/,/; $s/$/]/' | jq -r '(["id", "name", "symbol", "uniprotId", "chromosome", "start", "end"], (.[] | [._id, ._source.approved_name, ._source.approved_symbol, ._source.uniprot_id, ._source.chromosome, ._source.gene_start, ._source.gene_end])) | @csv' | gzip > $LOCAL_PROCESSED_DIR$VERTEX_GENE

echo "-- EFO"
gzcat $LOCAL_RAW_DIR$RAW_EFO | sed '1s/^/[/; $!s/$/,/; $s/$/]/' | jq -r '(["id", "name"], (.[] | [._id, ._source.label])) | @csv' | gzip > $LOCAL_PROCESSED_DIR$VERTEX_EFO

echo "-- TISSUE"
gzcat $LOCAL_RAW_DIR$RAW_EXPRESSION | head -n 1 | jq -r '(["id", "name"], (._source.tissues[] | [.efo_code, .label])) | @csv' | gzip > $LOCAL_PROCESSED_DIR$VERTEX_TISSUE

echo "Built loadable vertex files."

# ------- PREPARE EDGES DATA -------

echo "Building loadable edge files..."

echo "-- GENE -> TISSUE"
echo '"geneId","tissueId","rnaValue","rnaLevel","rnaZLevel","proteinLevel"' | gzip > $LOCAL_PROCESSED_DIR$EDGE_GENE_TISSUE
gzcat $LOCAL_RAW_DIR$RAW_EXPRESSION | jq -r '. as $in | ._source.tissues[] | . as $tissues | [$in._id] + [$tissues | .efo_code, .rna.value, .rna.level, .rna.zscore, .protein.level] | @csv' | gzip >> $LOCAL_PROCESSED_DIR$EDGE_GENE_TISSUE

echo "-- EFO -> EFO"
echo '"id","childId"' | gzip > $LOCAL_PROCESSED_DIR$EDGE_EFO_EFO
gzcat $LOCAL_RAW_DIR$RAW_EFO | jq -r '. as $in | ._source.children[] | . as $children | [$in._id] + [$children | .code] | @csv' | gzip >> $LOCAL_PROCESSED_DIR$EDGE_EFO_EFO

echo "-- GENE -> EFO"
# ALL
# gzcat $LOCAL_RAW_DIR$RAW_ASSOCS | sed '1s/^/[/; $!s/$/,/; $s/$/]/' | jq -r '(["geneId", "efoId", "score", "count"], (.[] | [.target.id, .disease.id, .association_score.overall, .evidence_count.total])) | @csv' | gzip > $LOCAL_PROCESSED_DIR$EDGE_GENE_EFO
# ONLY DIRECT (SHOULD BE ABLE TO INFER INDIRECT VIA EFO HIERARCHY TRAVERSAL)
gzcat $LOCAL_RAW_DIR$RAW_ASSOCS | grep '"is_direct": true' | sed '1s/^/[/; $!s/$/,/; $s/$/]/' | jq -r '(["geneId", "efoId", "score", "count"], (.[] | [.target.id, .disease.id, .association_score.overall, .evidence_count.total])) | @csv' | gzip > $LOCAL_PROCESSED_DIR$EDGE_GENE_EFO

echo "Built loadable edge files."

echo "Done. :)"
