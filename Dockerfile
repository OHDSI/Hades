# syntax=docker/dockerfile:1
FROM rocker/rstudio:4.2.3
LABEL Lee Evans <evans@ohdsi.org>

# install OS dependencies including java and python 3
RUN apt-get update && apt-get install -y openjdk-11-jdk liblzma-dev libbz2-dev libncurses5-dev curl python3-dev python3.venv \
&& R CMD javareconf \
&& rm -rf /var/lib/apt/lists/*

# install utility R packages
RUN install2.r \
	openssl \
	httr \
	xml2 \
	remotes \
&& rm -rf /tmp/download_packages/ /tmp/*.rds

# install OHDSI HADES R packages from CRAN and GitHub, temporarily adding a GitHub Personal Access Token (PAT) to the Renviron file
RUN --mount=type=secret,id=build_github_pat \
	cp /usr/local/lib/R/etc/Renviron /tmp/Renviron \
        && echo "GITHUB_PAT=$(cat /run/secrets/build_github_pat)" >> /usr/local/lib/R/etc/Renviron \
        && R -e "remotes::install_github(repo = 'OHDSI/Hades', upgrade = 'always')" \
        && cp /tmp/Renviron /usr/local/lib/R/etc/Renviron

# install useful R libraries to help RStudio users to create/use their own GitHub Personal Access Token
RUN install2.r \
        usethis \
        gitcreds \
&& rm -rf /tmp/download_packages/ /tmp/*.rds

# create Python virtual environment used by the OHDSI PatientLevelPrediction R package
ENV WORKON_HOME="/opt/.virtualenvs"
RUN R <<EOF
reticulate::use_python("/usr/bin/python3", required=T)
PatientLevelPrediction::configurePython(envname='r-reticulate', envtype='python')
reticulate::use_virtualenv("/opt/.virtualenvs/r-reticulate")
EOF

# install shiny and other R packages used by the OHDSI PatientLevelPrediction R package viewPLP() function
# and additional model related R packages
RUN install2.r \
        DT \
        markdown \
        plotly \
        shiny \
        shinycssloaders \
        shinydashboard \
        shinyWidgets \
        xgboost \
&& rm -rf /tmp/download_packages/ /tmp/*.rds

# install the jdbc drivers for database access using the OHDSI DatabaseConnector R package
ENV DATABASECONNECTOR_JAR_FOLDER="/opt/hades/jdbc_drivers"
RUN R -e "DatabaseConnector::downloadJdbcDrivers('all');"

# Install Rserve server and client
RUN install2.r \
	Rserve \
	RSclient \
&& rm -rf /tmp/download_packages/ /tmp/*.rds

# Rserve configuration
COPY Rserv.conf /etc/Rserv.conf
COPY startRserve.R /usr/local/bin/startRserve.R
RUN chmod +x /usr/local/bin/startRserve.R

EXPOSE 8787
EXPOSE 6311

# install supervisor process controller
RUN apt-get update && apt-get install -y supervisor

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
