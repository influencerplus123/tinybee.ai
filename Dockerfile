FROM python:2.7-alpine

ENV REDIS_SENTINEL=redis-sentinel
ENV REDIS_MASTER=mymaster

# install git and various python library dependencies with alpine tools
RUN set -x && \
    apk --no-cache add postgresql-dev g++ gcc git jpeg-dev libffi-dev libjpeg libxml2-dev libxslt-dev linux-headers musl-dev openssl zlib zlib-dev openldap-dev

# install python dependencies with pip
# install pybossa from git
# add unprivileged user for running the service
ENV LIBRARY_PATH=/lib:/usr/lib
RUN set -x && \
    git clone --recursive https://github.com/sfluo/tinybee /opt/tinybee && \
    cd /opt/tinybee && \
    pip install -U pip setuptools && \
    pip install -r /opt/tinybee/requirements.txt && \
    rm -rf /opt/tinybee/.git/ && \
    addgroup tinybee  && \
    adduser -D -G tinybee -s /bin/sh -h /opt/tinybee tinybee && \
    passwd -u tinybee

# variables in these files are modified with sed from /entrypoint.sh
ADD alembic.ini /opt/tinybee/
ADD settings_local.py /opt/tinybee/
ADD tinybee_logo.png /opt/tinybee/pybossa/static/img

# TODO: we shouldn't need write permissions on the whole folder
#   Known files written during runtime:
#     - /opt/tinybee/pybossa/themes/default/static/.webassets-cache
#     - /opt/tinybee/alembic.ini and /opt/tinybee/settings_local.py (from entrypoint.sh)
RUN chown -R tinybee:tinybee /opt/tinybee

ADD entrypoint.sh /
RUN ["chmod", "+x", "/entrypoint.sh"]
ENTRYPOINT ["/entrypoint.sh"]

# run with unprivileged user
USER tinybee
WORKDIR /opt/tinybee
EXPOSE 8080

# Background worker is also necessary and should be run from another copy of this container
#   python app_context_rqworker.py scheduled_jobs super high medium low email maintenance
CMD ["python", "run.py"]
