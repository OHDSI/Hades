# syntax=docker/dockerfile:1
FROM rocker/rstudio:4.4.1
LABEL org.opencontainers.image.authors="Lee Evans <evans@ohdsi.org>"
LABEL org.opencontainers.image.authors="nils.christian@ittm-solutions.com"
LABEL org.opencontainers.image.authors="christian.bauer@ittm-solutions.com"

# install OS dependencies including java and python 3
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
        openjdk-11-jdk libpcre2-dev zlib1g-dev liblzma-dev libbz2-dev libicu-dev libxml2-dev libncurses5-dev libffi-dev \
        make cmake libpng-dev libsodium-dev curl python3-dev python3-venv python3-pip \
        libdeflate-dev unixodbc-dev libcurl4-openssl-dev xz-utils git pandoc supervisor \
        libsecret-1-0 \
&& R CMD javareconf

# CRAN snapshot date
ARG POSIT_DATE=2024-12-31

# Ubuntu codename
ARG CODENAME=jammy

# make installation of dependencies reproducible by using a repository snapshot; set user agent to ensure binary packages are downloaded
COPY <<-EOF /usr/local/lib/R/etc/Rprofile.site
    options(repos=c(CRAN='https://packagemanager.posit.co/cran/__linux__/$CODENAME/$POSIT_DATE'))
    options(renv.config.repos.override = c(CRAN='https://packagemanager.posit.co/cran/__linux__/$CODENAME/$POSIT_DATE'))
    options(HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(), paste(getRversion(), R.version["platform"], R.version["arch"], R.version["os"])))
    options(download.file.extra = sprintf('--header "User-Agent: R (%s)"', paste(getRversion(), R.version["platform"], R.version["arch"], R.version["os"])))
EOF

# install renv package
RUN --mount=type=cache,target=/tmp/downloaded_packages \
    install2.r --error --skipinstalled renv

# HADES wide release
ARG HADES_RELEASE=2024Q3
ARG RENV_LOCK=hadesWideReleases/$HADES_RELEASE/renv.lock
COPY $RENV_LOCK /renv.lock

# install OHDSI HADES R packages and additional model related R packages, Rserve server and client
# from CRAN and GitHub using a GitHub Personal Access Token (PAT)
RUN --mount=type=secret,id=GITHUB_PAT,env=GITHUB_PAT \
    --mount=type=cache,target=/root/.cache/R/renv \
    Rscript --no-save --no-restore --no-echo \
    -e "library(renv); options(renv.verbose = TRUE); renv::restore(lockfile='/renv.lock')" \
    -e "renv::install(c('usethis@3.1.0', 'gitcreds@0.1.2', 'xgboost@1.7.8.1', 'Rserve@1.8-13', 'RSclient@0.7-10'));"

# create Python virtual environment used by the OHDSI PatientLevelPrediction R package
ENV WORKON_HOME="/opt/.virtualenvs"
RUN --mount=type=cache,target=/root/.cache/pip R <<EOF
    reticulate::use_python("/usr/bin/python3", required=T)
    PatientLevelPrediction::configurePython(envname='r-reticulate', envtype='python')
    reticulate::use_virtualenv("/opt/.virtualenvs/r-reticulate")
EOF

# install the jdbc drivers for database access using the OHDSI DatabaseConnector R package
ENV DATABASECONNECTOR_JAR_FOLDER="/opt/hades/jdbc_drivers"
RUN Rscript --no-save --no-restore --no-echo -e "DatabaseConnector::downloadJdbcDrivers('all');" \
    && rm -rf /tmp/hsperfdata_root

# after reproducible installation of R packages, use repository with latest packages available.
COPY <<-EOF /usr/local/lib/R/etc/Rprofile.site
    options(repos=c(CRAN='https://packagemanager.posit.co/cran/__linux__/$CODENAME/latest'))
    options(renv.config.repos.override = c(CRAN='https://packagemanager.posit.co/cran/__linux__/$CODENAME/latest'))
    options(HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(), paste(getRversion(), R.version["platform"], R.version["arch"], R.version["os"])))
    options(download.file.extra = sprintf('--header "User-Agent: R (%s)"', paste(getRversion(), R.version["platform"], R.version["arch"], R.version["os"])))
EOF

# Rserve configuration
COPY Rserv.conf /etc/Rserv.conf
COPY startRserve.R /usr/local/bin/startRserve.R
RUN chmod +x /usr/local/bin/startRserve.R

EXPOSE 8787
EXPOSE 6311

# start Rserve & RStudio using supervisor
RUN echo "" >> /etc/supervisor/conf.d/supervisord.conf \
    && echo "[supervisord]" >> /etc/supervisor/conf.d/supervisord.conf \
    && echo "nodaemon=true" >> /etc/supervisor/conf.d/supervisord.conf \
    && echo "" >> /etc/supervisor/conf.d/supervisord.conf \
    && echo "[program:Rserve]" >> /etc/supervisor/conf.d/supervisord.conf \
    && echo "command=/usr/local/bin/startRserve.R" >> /etc/supervisor/conf.d/supervisord.conf \
    && echo "" >> /etc/supervisor/conf.d/supervisord.conf \
    && echo "[program:RStudio]" >> /etc/supervisor/conf.d/supervisord.conf \
    && echo "command=/init" >> /etc/supervisor/conf.d/supervisord.conf \
    && echo "" >> /etc/supervisor/conf.d/supervisord.conf \
    && echo "stdout_logfile=/var/log/supervisor/%(program_name)s.log" >> /etc/supervisor/conf.d/supervisord.conf \
    && echo "stderr_logfile=/var/log/supervisor/%(program_name)s.log" >> /etc/supervisor/conf.d/supervisord.conf

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
