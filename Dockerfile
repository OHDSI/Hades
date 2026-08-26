# syntax=docker/dockerfile:1
FROM rocker/rstudio:4.4.1
LABEL org.opencontainers.image.authors="Lee Evans <evans@ohdsi.org>, Nils Christian <nils.christian@ittm-solutions.com>"

# install OS dependencies including java and python 3
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
        cmake \
        curl \
        git \
        libbz2-dev \
        libcurl4-openssl-dev \
        libdeflate-dev \
        libffi-dev \
        libfontconfig1-dev \
        libfreetype6-dev \
        libfribidi-dev \
        libgit2-dev \
        libglpk-dev \
        libharfbuzz-dev \
        libicu-dev \
        libjpeg-dev \
        liblzma-dev \
        libncurses5-dev \
        libnode-dev \
        libpcre2-dev \
        libpng-dev \
        libsecret-1-dev \
        libsodium-dev \
        libssl-dev \
        libtiff-dev \
        libwebp-dev \
        libx11-dev \
        libxml2-dev \
        make \
        openjdk-11-jdk \
        pandoc \
        python3 \
        python3-dev \
        python3-pip \
        python3-venv \
        unixodbc-dev \
        xz-utils \
        zlib1g-dev \
&& R CMD javareconf

# CRAN snapshot date
ARG POSIT_DATE=2025-10-03

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
ARG HADES_RELEASE=2025Q3
ARG RENV_LOCK=hadesWideReleases/$HADES_RELEASE/renv.lock
COPY $RENV_LOCK /renv.lock

# install OHDSI HADES R packages and additional model related R packages, Rserve client
# from CRAN and GitHub using a GitHub Personal Access Token (PAT)
RUN --mount=type=secret,id=GITHUB_PAT,env=GITHUB_PAT \
    --mount=type=cache,target=/root/.cache/R/renv \
    Rscript --no-save --no-restore --no-echo \
    -e "library(renv); options(renv.verbose = TRUE); renv::restore(lockfile='/renv.lock')" \
    -e "renv::install(c('RSclient@0.7-10'));"

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

EXPOSE 8787
