docker build --no-cache -t afmichelutti/omniflex_cw_4111 .
docker push afmichelutti/omniflex_cw_4111

docker build --no-cache -t afmichelutti/omniflex_cw_4111:appio .
docker push afmichelutti/omniflex_cw_4111:appio
