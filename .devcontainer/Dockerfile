FROM ghcr.io/rocker-org/devcontainer/tidyverse:4

USER root

RUN Rscript -e "install.packages('pheatmap', repos='https://cloud.r-project.org')"

# 단일 사용자용 서버 데이터와 DB 설정
RUN mkdir -p /home/rstudio/.local/share/rstudio-server \
    && printf '%s\n' \
       'provider=sqlite' \
       'directory=/home/rstudio/.local/share/rstudio-server' \
       > /home/rstudio/.local/share/rstudio-server/database.conf \
    && chown -R rstudio:rstudio \
       /home/rstudio/.local/share/rstudio-server

# 기존 설정에 추가하지 않고 전체 설정을 명시
RUN printf '%s\n' \
    'rsession-which-r=/usr/local/bin/R' \
    'server-user=rstudio' \
    'auth-none=1' \
    'server-data-dir=/home/rstudio/.local/share/rstudio-server' \
    'database-config-file=/home/rstudio/.local/share/rstudio-server/database.conf' \
    > /etc/rstudio/rserver.conf
