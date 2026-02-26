## VPS

root@srv463687:~# docker stats --no-stream
CONTAINER ID NAME CPU % MEM USAGE / LIMIT MEM % NET I/O BLOCK I/O PIDS
79f38becbd24 backend-finkos_backend-finkos.1.qlrcqbox5g95eglyys9hz9zbh 0.00% 249.6MiB / 512MiB 48.74% 161MB / 71.6MB 47.9MB / 27.6MB 46
dbaf15dbaa4d backend-ai_backend-ai.1.ku7bku3dqo7dbucrwkluubgmu 0.40% 774.7MiB / 2GiB 37.83% 908MB / 534MB 4.79MB / 1.68MB 22
48790bfcb5fa backend-qorder_backend-qorder.1.unhq4fxbxrugwvmbz120zgs37 0.00% 202.7MiB / 512MiB 39.59% 60.2MB / 42.6MB 6.33MB / 4.1kB 34
8cac9dca7766 whatsapp_redis_whatsapp.1.khwr5eg29rkj4rx31mumtu8tx 0.37% 31.62MiB / 31.36GiB 0.10% 205MB / 59.4MB 129MB / 5GB 7
e1ad1cfc8565 whatsapp_conector.1.viuqkbe1472u5w2xwr7jbkagw 0.16% 213.6MiB / 31.36GiB 0.67% 549MB / 689MB 71.7MB / 66.3MB 31
102065c5a1ae whatsapp_rabbitmq_whatsapp.1.oyg5fkqzpksz2ujx5opxyt1r4 0.65% 177.3MiB / 31.36GiB 0.55% 70.4MB / 25.9MB 5.26MB / 535MB 41
b2ec13885ba3 backups3_backups3.1.qmnyqq708rya4dndgcyn3w0t0 0.00% 25.29MiB / 512MiB 4.94% 47.2GB / 52.4MB 26.8MB / 5.89GB 7
88343f4be5a5 metabase_qorder_metabase.1.i82yc49500ud283toegtih21e 1.02% 2.728GiB / 31.36GiB 8.70% 6.14GB / 1.81GB 11.7MB / 1.45GB 105
ac49c9de53c4 flowise_flowise.1.dotn98vqjcgfb1nq59byhv882 0.00% 385.2MiB / 8GiB 4.70% 319MB / 283MB 67.3MB / 4.03MB 11
ee5aed68d2c6 mongodb_mongodb.1.o0yv291u13mh9j0lw4eaknpva 1.03% 201.1MiB / 1GiB 19.64% 1.5MB / 410kB 4.76MB / 10.4GB 32
a73cf10c5ac9 n8n_redis.1.wzmr1145m3ab69soz9wmcb3fm 0.72% 11.52MiB / 512MiB 2.25% 2.58GB / 785MB 10.3GB / 11.7GB 7
649dac4c6eea syncapp-api_syncapp-redis.1.5kwvvezn25nz6o0g3r4b99t9n 0.55% 8.879MiB / 256MiB 3.47% 40.4MB / 39.4MB 5.99MB / 0B 6
a570281e80b1 chatwoot_admin_chatwoot_admin.1.v1cybidnnqvtcx60eubm8goel 0.44% 1.085GiB / 4GiB 27.12% 2.42GB / 1.94GB 93.1MB / 264MB 82
3727df8a7b89 chatwoot_admin_chatwoot_sidekiq.1.cultf287gewn1ygymcipymo46 1.05% 656.7MiB / 6GiB 10.69% 8.76GB / 17.8GB 90.2MB / 42.1MB 37
4d883b452437 portainer_agent.7qhf6tznbgeufjnxorax6l64y.tj3c7cxr7io7laq1vlibad685 0.23% 41.96MiB / 31.36GiB 0.13% 388MB / 6.18GB 37.2MB / 8.19kB 11
425ed36318b8 monitor_postgres-exporter.1.okivmlyioct3mg462ezltsjsm 0.00% 25.45MiB / 31.36GiB 0.08% 14.6GB / 6.53GB 13.6MB / 0B 12
9bb5522e4ce0 monitor_grafana.1.e0qafi3uxwlqssjz1i8n9zw7e 1.22% 185MiB / 31.36GiB 0.58% 48.9MB / 20.6MB 279MB / 1.88GB 17
81341c495ff7 crypto_crypto-backend.1.wu4g8g0meloqa55sfn3q7cdla 1.34% 650.3MiB / 1GiB 63.50% 127MB / 165MB 138MB / 8.19kB 35
3491ae600c01 n8n_n8n_worker.2.vi010yfak8wip4cw8mmgrfh1r 130.68% 261.7MiB / 2GiB 12.78% 564MB / 1.21GB 69.3MB / 6.66MB 20
223280899a53 minio_minio.1.1n3931bx1c1xebhd70x0geqwb 0.04% 274.9MiB / 512MiB 53.69% 3.32GB / 97.6MB 149MB / 7.44GB 18
7f05d13c2893 n8n_n8n_webhook.1.yljmlhvuo5e6st4rt99j1d71m 0.14% 233.4MiB / 2GiB 11.40% 484MB / 799MB 53.3MB / 12.9MB 13
aaa4db6c84b6 directus_chatwoot_directus_chatwoot.1.m500t4saitmlqrjmtroc5zaqs 1.79% 213.4MiB / 31.36GiB 0.66% 39.3MB / 38MB 88.2MB / 2.24MB 22
a264ab6092b5 monitor_node-exporter.7qhf6tznbgeufjnxorax6l64y.v3k4nd9grkaoo43yjxj6jgg9r 0.00% 25.14MiB / 31.36GiB 0.08% 131MB / 3.22GB 15.9MB / 0B 18
2e10d1f1d7fc monitor_prometheus.1.w4dow94fklbiabof42vgvdidb 1.31% 138.3MiB / 31.36GiB 0.43% 6.92GB / 273MB 82.4MB / 9.57GB 14
f8c366fe3e7d site_portal.1.pho5nyp8mkjq70nlz0ks7cdm7 0.00% 32.99MiB / 1GiB 3.22% 3.56MB / 157MB 13.7MB / 4.11MB 55
fa557d8c12a3 syncapp-api_syncapp-api.1.n168wvm5cy5ng2tvelg9f1ewy 0.00% 95.35MiB / 512MiB 18.62% 135MB / 207MB 81.1MB / 224MB 15
69ff78b8ebb9 agent-ai-backend_agent-ai-backend.1.vef83qv8ejgxvkcrnovdhfevt 0.00% 32.37MiB / 512MiB 6.32% 1.17MB / 89.3kB 11MB / 274kB 11
2ddc9e8b84b3 crypto_crypto-frontend.1.l4xmjo6godhysofjf8ajrwrab 0.00% 11.46MiB / 256MiB 4.48% 1.1MB / 2.21MB 8.75MB / 8.19kB 9
946810e6da00 aimedical_api-aimedical.1.ft4guw5y730vmifcyurgawse6 0.31% 182.3MiB / 31.36GiB 0.57% 1.52MB / 84.1kB 181MB / 717kB 17
c733f74729aa mongodb2_mongodb2.1.tlmnelt5a0zlt7tmem6sgaepc 1.49% 261.7MiB / 1GiB 25.55% 1.29MB / 89.6kB 103MB / 10GB 32
9a27d7d3d8ba gestor_qmenu_gestor_qmenu.1.nmraro84nlm4pkis2xoap4a1l 0.00% 9.848MiB / 512MiB 1.92% 968kB / 0B 7.39MB / 12.3kB 9
d4934b222aa3 backend-waba_backend-waba.1.spgbjpsb22vlmu2zjkjf2sg69 0.22% 342.3MiB / 31.36GiB 1.07% 1.76GB / 3.53GB 102MB / 2.36MB 33
6da609ff74c2 postgres_postgres.1.pp4r7dgp6mbztjh6nfhcikmmd 0.50% 4.231GiB / 8GiB 52.88% 17GB / 114GB 3.71GB / 20GB 121
3fc58d6a26af traefik_traefik.1.y0snqih64cijyg7c4kbhtx1gh 0.09% 157.6MiB / 31.36GiB 0.49% 51.7GB / 52GB 98.2MB / 3.02GB 15
0a44a79f0d7f n8n_n8n_worker.1.jd46vwhnixlozjaebulcgti7c 133.40% 279.2MiB / 2GiB 13.63% 574MB / 1.22GB 15.6MB / 28.3MB 20
d4a645df409a chatwoot_admin_chatwoot_redis.1.ka3cr8lj10chtix9hpg00ze8p 0.92% 17.86MiB / 512MiB 3.49% 18.1GB / 6.67GB 2.53GB / 6.65GB 7
1ee9d9028d2d directus_qorder_directus_qorder.1.zaupuv4tkqxevv1ankctg8lci 1.83% 247.8MiB / 4GiB 6.05% 12.9GB / 50.7GB 53.6MB / 525MB 22
0667b82625ed qdrant_qdrant.1.mroqx483432jo8vdtmi2uev9g 0.22% 381.3MiB / 1GiB 37.24% 976MB / 82.7MB 264MB / 1.77GB 36
800ece46d7f3 rabbitmq_rabbitmq.1.z6bw16mpmcyvyqqadavw4mn7s 0.95% 144MiB / 512MiB 28.12% 1.28MB / 3.58MB 57.3MB / 69.6kB 38
7aba0773d4cf backend-waba_backend-waba-redis.1.tl1jrsexpgrqo1frfilm57hxm 0.76% 112.3MiB / 512MiB 21.93% 3.44GB / 1.62GB 2.05GB / 243GB 7
2dbe6ff55930 typebot_builder_typebot_builder.1.kbk1kqo30iqztori1tl6zjsx8 0.00% 186.9MiB / 1GiB 18.25% 2.77MB / 11.5MB 100MB / 12.3kB 15
b50dd99aa3ea n8n_n8n_editor.1.a8wmcvvwn1tqi629n2vj95v0t 129.52% 293.2MiB / 2GiB 14.32% 403MB / 847MB 87.6MB / 46.5MB 20
9c94e1e7d04c portainer_portainer.1.bx04qjehdyc798cke6v4v608h 0.03% 92.94MiB / 31.36GiB 0.29% 6.2GB / 520MB 120MB / 1.63GB 11
c8ccba17efcc letters_backend_letters_backend.1.64m68cp5yue60ndhirwnea8vn 0.00% 62.82MiB / 768MiB 8.18% 2.36MB / 981kB 85MB / 467kB 11
2f38cba1de2c redis_redis.1.8h2yhfdrpcy15po7t0ufoho1d 0.44% 537.9MiB / 1GiB 52.53% 5.71MB / 40.8MB 536MB / 102GB 6
1f9e78fbc824 appio_mongodb_appio_mongodb.1.jed1p3woy2mzd57ile01m58ty 1.21% 200MiB / 1GiB 19.53% 969kB / 0B 9.73MB / 9.98GB 32
a7fd3ab40f52 n8n_n8n_webhook.2.596403pd1n4l5uieotzkaofil 2.26% 204.8MiB / 2GiB 10.00% 507MB / 916MB 13.4MB / 11.4MB 13
d52f15b6829d typebot_viewer_typebot_viewer.1.x0qsplj8bughqkf9nb08tg93w 0.00% 189.8MiB / 1GiB 18.54% 9.36MB / 7.02MB 88.7MB / 4.1kB 16
root@srv463687:~# ^C

root@srv463687:~# free --h
free: option '--h' is ambiguous; possibilities: '--human' '--help'

Usage:
free [options]

Options:
-b, --bytes show output in bytes
--kilo show output in kilobytes
--mega show output in megabytes
--giga show output in gigabytes
--tera show output in terabytes
--peta show output in petabytes
-k, --kibi show output in kibibytes
-m, --mebi show output in mebibytes
-g, --gibi show output in gibibytes
--tebi show output in tebibytes
--pebi show output in pebibytes
-h, --human show human-readable output
--si use powers of 1000 not 1024
-l, --lohi show detailed low and high memory statistics
-t, --total show total for RAM + swap
-s N, --seconds N repeat printing every N seconds
-c N, --count N repeat printing N times, then exit
-w, --wide wide output

     --help     display this help and exit

-V, --version output version information and exit

For more details see free(1).
root@srv463687:~#

root@srv463687:~# df -h
Filesystem Size Used Avail Use% Mounted on
udev 16G 0 16G 0% /dev
tmpfs 3.2G 4.9M 3.2G 1% /run
/dev/sda1 394G 99G 280G 26% /
tmpfs 16G 0 16G 0% /dev/shm
tmpfs 5.0M 0 5.0M 0% /run/lock
/dev/sda15 124M 11M 114M 9% /boot/efi
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/2c237216107921f1b4d0d6677f93adc5ca016c128d4e4f20fb3169f43bebd771/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/de04123ece0aa91dbf5795abad5c2e576bae4cdcc7b7ba0b1ea93e4765b771f7/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/23466ca931b04fb023dfe879aaf295e5db4c21778f0bbaf96c08f98594c35d11/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/4fca9517d52dbfc9d2efd483de800496f14f497bbbb26fd388df2e3802ffaadb/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/54e6db0f8128acf65cdaddb828ee6573933c00b1d0907d4976459b611268d4cf/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/25ef32e3c873ef7c9e3ef5079cb57da72df1064a95bd1794c8a72a75365abf70/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/f640c894641943e1c5036ee0b093107a71e7b20e2266355d0b850ed18512e55e/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/f324f19415d1999851824954ad332d424e24c7c169df197a7b1f58174214b342/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/90360f2a97936c768c0a93d0568778c4abd18ccfb654d6e4eb2fa421d78995bd/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/6ebcf80c8519ace1ad67e8893c23938d78f1f5446352daf5b75e15cc3209c560/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/df951ba72b1b9a927732e5c047950764edbd7117a0d96b724b433acba86fb162/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/8d2ee2f94a949ea25b37e4f4c4b75274b90eb27c095a942775cc96bed047a786/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/a3a0af6fd3fe1b040a32e3975e860378509921c51925b2814c45cc9499583eac/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/093544e28f8842d0ad88c6ff2a800063512290e34965383e17c317570afb9ce3/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/0547e72a9dfb18d2dfa4663f31a33aabe260ba82226a2f5880111650d0189e53/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/7a04a80d7df72f4fccb2bf56620aec1671c23e208a147b9ca4ccd43bab87bef9/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/59a38cd959bd98e559c73cbad75b3be7069b5bbe9c5e3d87cc478457adfae4b4/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/8ad029b4a4745316d5f9d60e4c241525cb2c2c4c239cfc1063fbbed88d4be25f/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/572b1065149d5507b2698f83ac5c97aa357c495cc1602926454ba07e468521b8/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/0d27fc7e11dac90ca09b27260076bd7809b12ecd0ad51f3a9ccf4695800d9f7d/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/2e6311e7ebce8372afdd082e566c8aa17af89a661d7354e116b04f4f7121d64f/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/d6138f004a4b59ef53b2405fd72ba32e20144bc33225fdd150dea093bec0708e/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/3999dd21711ac6eec4b19858e7b5babe851843439f7f3d111e70167b3b6f04e6/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/f9bc603486e34fa6b9f1ea6564aeb7299355421094f2333a126f22ed9906b6ef/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/9035f01a1ea3ac47786c66d97225954743cc167e6f33a68b51938bab5f51fe7c/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/c03cda8926f41cb0ba04ad0bb70709413e03a3968565ec5c271b4eea6f4ad0da/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/86c27be8204cef0a8559730218deaf5441318a58e45f79da8ec435c6f67d449c/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/588ca67bfe3f6b1f4e6c5f468983e3012771e8686f22ab1e148f323537ce8805/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/479ddd09304551cf2e02cf21f3ff1aaf556abb73c4b62fe97b7d9aa5d003095d/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/181f52abc4e2073ad809cacd99a8672374335ffde20562725799b82a38e16108/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/46d63479c63a4004b93bf1148792affd464f5161a9c3aab6fbfc0e60ff7ee82d/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/dc120ba45f0b1f9e5f5ac2370462a1ecd054a9896c4ba36e4fa845cb4693d30b/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/2b255d89847fa18f69966e3a62cdc776d059115abf908a38850a917e6030b948/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/f13ce62a289e37765e356ef0521fdee583a996e29ab6415bad83edf5129ca1cf/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/ad94fcd0f9b8f5744dbb6fb62831099fd91a627640815439f04596c7712844ce/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/dea7615e43092894e7943bfbdd3a2c80a7a064fa45428a7821a773757aa36b80/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/dabaf792ed84ce6345aaa143fcc43f2dbdccde8b926b1afe346ccb2052d424aa/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/68d9d30558e31b7413f59b99fbdf2dae3f376b45a84ec631c0c434b730059150/merged
tmpfs 16G 4.0K 16G 1% /var/lib/docker/containers/2e10d1f1d7fc57e3c5b374e7c1d97f7e4b250c438623ac345899e3cc3c97027f/mounts/secrets
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/068e1d0b671c165c8870a656a3f26d9ab56420db44069aa25a8b0dd86e780e7c/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/b778d478a74a12c046d0bec089bc1aa4da1e2cf2031ca94ad9178848a77af20b/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/dd63581786ff24cb929b840618587d1bd122fa6d129be2aa129c1c5a2a2e5177/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/a50c6ac0883ffd93b59a755667106a7c2849f1818df0913541e67fa50b0f41f2/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/3814fb0ea3e1915e64389ca9bf78096f05a8470eb9d94202ede1947401bb3715/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/7a2d4ae135b969539130cdcba0cea4512611dfdd16d5bf791080f9e8cbcd17f2/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/33cb58ff2f21780d55705dc144dae9d4e5ccc3349d3e1202bc348e6e251c86f3/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/1bd688e8396b7d11a87c9e6d96781d3fb857efc167a9061b497f49a5ef82e14f/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/6dc11423a0ab9f4bd2e875797768c77df37b8fd142410fe50682276c3d4b4929/merged
overlay 394G 99G 280G 26% /var/lib/docker/overlay2/68fef2c883807a6831b4b24196cad97312347725493a8139f108c1c6445faeb6/merged
tmpfs 3.2G 0 3.2G 0% /run/user/0
root@srv463687:~#

nproc: 8

yaml chatwoot versão 3.5.2

version: "3.7"

##############

#

# Chatwoot Stack Unificado - Otimizado para Hetzner KM8

# 8 cores CPU, 16GB RAM

#

# Setup Inicial:

# 1. docker exec -it <container_admin> bundle exec rails db:chatwoot_prepare

#

# Documentação:

# https://www.chatwoot.com/docs/self-hosted/configuration/environment-variables

#

##############

services:

# ============================================

# Redis exclusivo do Chatwoot (sem senha)

# ============================================

chatwoot_redis:
image: redis:7-alpine
command: redis-server --appendonly yes
restart: unless-stopped
networks: - network_public
volumes: - chatwoot_redis_data:/data
deploy:
resources:
limits:
cpus: "0.5"
memory: 512M
reservations:
cpus: "0.25"
memory: 256M

# ============================================

# Chatwoot Web Server (Rails)

# ============================================

chatwoot_admin:
image: afmichelutti/cw_agent_permission:v1.0.4
command: bundle exec rails s -p 3000 -b 0.0.0.0
entrypoint: docker/entrypoints/rails.sh

    volumes:
      - chatwoot_data:/app/storage

    networks:
      - network_public

    environment:
      # ===== Configuração Básica =====
      - INSTALLATION_NAME=${CW_INSTALLATION_NAME:-Appio}
      - NODE_ENV=production
      - RAILS_ENV=production
      - INSTALLATION_ENV=docker
      - SECRET_KEY_BASE=${CW_SECRET_KEY_BASE}
      - FRONTEND_URL=${CW_FRONTEND_URL}
      - DEFAULT_LOCALE=pt_BR
      - FORCE_SSL=true
      - ENABLE_ACCOUNT_SIGNUP=${CW_ENABLE_SIGNUP:-true}

      # ===== Redis (exclusivo do Chatwoot) =====
      - REDIS_URL=redis://chatwoot_redis:6379/1
      # Sem senha

      # ===== PostgreSQL =====
      - POSTGRES_HOST=${CW_POSTGRES_HOST:-postgres}
      - POSTGRES_PORT=${CW_POSTGRES_PORT:-5432}
      - POSTGRES_USERNAME=${CW_POSTGRES_USERNAME}
      - POSTGRES_PASSWORD=${CW_POSTGRES_PASSWORD}
      - POSTGRES_DATABASE=${CW_POSTGRES_DATABASE}

      # ===== AWS S3 Storage =====
      - ACTIVE_STORAGE_SERVICE=amazon
      - AWS_ACCESS_KEY_ID=${CW_AWS_ACCESS_KEY_ID}
      - AWS_SECRET_ACCESS_KEY=${CW_AWS_SECRET_ACCESS_KEY}
      - AWS_REGION=${CW_AWS_REGION:-sa-east-1}
      - S3_BUCKET_NAME=${CW_S3_BUCKET_NAME}

      # ===== SMTP Email =====
      - MAILER_SENDER_EMAIL=${CW_MAILER_SENDER_EMAIL}
      - SMTP_ADDRESS=${CW_SMTP_ADDRESS:-smtp.sendgrid.net}
      - SMTP_PORT=${CW_SMTP_PORT:-587}
      - SMTP_USERNAME=${CW_SMTP_USERNAME}
      - SMTP_PASSWORD=${CW_SMTP_PASSWORD}
      - SMTP_DOMAIN=${CW_SMTP_DOMAIN}
      - SMTP_AUTHENTICATION=plain
      - SMTP_ENABLE_STARTTLS_AUTO=true

      # ===== Performance Tuning (KM8) =====
      - WEB_CONCURRENCY=3
      - RAILS_MAX_THREADS=10

      # ===== Logs & Segurança =====
      - RAILS_LOG_TO_STDOUT=true
      - USE_INBOX_AVATAR_FOR_BOT=true
      - ENABLE_RACK_ATTACK=true
      - RACK_ATTACK_LIMIT=${CW_RATE_LIMIT:-5000}

    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints:
          - node.role == manager
      resources:
        limits:
          cpus: "3"
          memory: 4096M
        reservations:
          cpus: "1.5"
          memory: 2048M
      labels:
        # Traefik Configuration
        - traefik.enable=true
        - traefik.http.routers.chatwoot_admin.rule=Host(`${CW_DOMAIN}`)
        - traefik.http.routers.chatwoot_admin.entrypoints=websecure
        - traefik.http.routers.chatwoot_admin.tls.certresolver=letsencryptresolver
        - traefik.http.routers.chatwoot_admin.service=chatwoot_admin
        - traefik.http.services.chatwoot_admin.loadbalancer.server.port=3000
        - traefik.http.services.chatwoot_admin.loadbalancer.passhostheader=true
        # SSL & WebSocket Headers
        - traefik.http.middlewares.sslheader.headers.customrequestheaders.X-Forwarded-Proto=https
        - traefik.http.routers.chatwoot_admin.middlewares=sslheader@docker

# ============================================

# Chatwoot Sidekiq (Background Jobs)

# ============================================

chatwoot_sidekiq:
image: afmichelutti/cw_agent_permission:v1.0.4
command: bundle exec sidekiq -C config/sidekiq.yml

    volumes:
      - chatwoot_data:/app/storage

    networks:
      - network_public

    environment:
      # ===== Mesmas variáveis do admin =====
      - INSTALLATION_NAME=${CW_INSTALLATION_NAME:-Appio}
      - NODE_ENV=production
      - RAILS_ENV=production
      - INSTALLATION_ENV=docker
      - SECRET_KEY_BASE=${CW_SECRET_KEY_BASE}
      - FRONTEND_URL=${CW_FRONTEND_URL}
      - DEFAULT_LOCALE=pt_BR
      - FORCE_SSL=true

      # ===== Redis (exclusivo do Chatwoot) =====
      - REDIS_URL=redis://chatwoot_redis:6379/1

      # ===== PostgreSQL =====
      - POSTGRES_HOST=${CW_POSTGRES_HOST:-postgres}
      - POSTGRES_PORT=${CW_POSTGRES_PORT:-5432}
      - POSTGRES_USERNAME=${CW_POSTGRES_USERNAME}
      - POSTGRES_PASSWORD=${CW_POSTGRES_PASSWORD}
      - POSTGRES_DATABASE=${CW_POSTGRES_DATABASE}

      # ===== AWS S3 =====
      - ACTIVE_STORAGE_SERVICE=amazon
      - AWS_ACCESS_KEY_ID=${CW_AWS_ACCESS_KEY_ID}
      - AWS_SECRET_ACCESS_KEY=${CW_AWS_SECRET_ACCESS_KEY}
      - AWS_REGION=${CW_AWS_REGION:-sa-east-1}
      - S3_BUCKET_NAME=${CW_S3_BUCKET_NAME}

      # ===== SMTP =====
      - MAILER_SENDER_EMAIL=${CW_MAILER_SENDER_EMAIL}
      - SMTP_ADDRESS=${CW_SMTP_ADDRESS:-smtp.sendgrid.net}
      - SMTP_PORT=${CW_SMTP_PORT:-587}
      - SMTP_USERNAME=${CW_SMTP_USERNAME}
      - SMTP_PASSWORD=${CW_SMTP_PASSWORD}
      - SMTP_DOMAIN=${CW_SMTP_DOMAIN}
      - SMTP_AUTHENTICATION=plain
      - SMTP_ENABLE_STARTTLS_AUTO=true

      # ===== Sidekiq Performance (KM8) =====
      - SIDEKIQ_CONCURRENCY=30
      - RAILS_MAX_THREADS=30

      # ===== Logs =====
      - RAILS_LOG_TO_STDOUT=true
      - USE_INBOX_AVATAR_FOR_BOT=true

    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints:
          - node.role == manager
      resources:
        limits:
          cpus: "4"
          memory: 6144M
        reservations:
          cpus: "2"
          memory: 3072M

# ============================================

# Volumes & Networks

# ============================================

volumes:
chatwoot_data:
external: true
name: chatwoot_data

chatwoot_redis_data:
driver: local

networks:
network_public:
external: true
name: network_public
