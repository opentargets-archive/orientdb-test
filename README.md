# OrientDB - Proof of Concept

This repo builds a dockerised instance of OrientDB containing platform data stored as a graph.

## Query benchmarks

The intention is to test some of the more complex queries used in the platform and benchmark them.

Some examples of such queries are:

- Get all genes that are associated with a specific disease, such that they have a RNA expression level above some threshold in one or more tissues
- Get the aggregated counts, per RNA expression level and per tissue, of all genes that are associated with a specific disease
- Get all genes that are associated with a specific disease or are associated with a child of the specific disease (ie. indirect associations)

Other queries that are not currently used in the platform, but lend themselves to a graph structure, might also be explored.

## Setup instructions

Clone this repo.

Download and prepare the data for OrientDB:

```
bash prepare-data.sh
```

Run OrientDB in a docker container (sharing the processed data):

```
docker run -v $PWD/data:/etl/data -v$PWD/loaders:/etl/loaders -e ORIENTDB_ROOT_PASSWORD=root -p 2424:2424 -p 2480:2480 -d --name otorient orientdb
```

Attach to the container and run the ETL steps (it is important that vertices are before edges):

```
docker exec -it otorient /bin/sh
$ cd bin
$ oetl.sh /etl/loaders/vertex-gene.json
$ oetl.sh /etl/loaders/vertex-efo.json
$ oetl.sh /etl/loaders/vertex-tissue.json
$ oetl.sh /etl/loaders/edge-gene-efo.json
$ oetl.sh /etl/loaders/edge-gene-tissue.json
```

You should now be able to browse the database `opentargets` in OrientDB Studio at http://localhost:2480. Username and password are both `root`.
