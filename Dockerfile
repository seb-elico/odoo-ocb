FROM ubuntu:14.04
MAINTAINER Elico-Corp <info@elico-corp.com>

# generate locales
RUN locale-gen en_US.UTF-8 && update-locale
RUN echo 'LANG="en_US.UTF-8"' > /etc/default/locale

# Add the PostgreSQL PGP key to verify their Debian packages.
# It should be the same key as https://www.postgresql.org/media/keys/ACCC4CF8.asc
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8

# Add PostgreSQL's repository. It contains the most recent stable release
#     of PostgreSQL, ``9.4``.
# install dependencies as distrib packages when system bindings are required
# some of them extend the basic odoo requirements for a better "apps" compatibility
# most dependencies are distributed as wheel packages at the next step
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
        apt-get update && \
        apt-get -yq install \
            adduser \
            ghostscript \
            postgresql-client-9.4 \
            python \
            python-pip \
            python-imaging \
            python-pychart python-libxslt1 xfonts-base xfonts-75dpi \
            libxrender1 libxext6 fontconfig \
            python-zsi \
            python-lasso \
            # SM: libpq-dev is needed to install pg_config which is required by psycopg2
            libpq-dev \
            # SM: These libraries are needed to install the pip modules
            python-dev \
            libffi-dev \
            libxml2-dev \
            libxslt1-dev \
            libldap2-dev \
            libsasl2-dev \
            libssl-dev \
            # SM: This library is necessary to upgrade PIL/pillow module
            libjpeg8-dev \
            # SM: Git is required to clone Odoo OCB project
            git

ADD sources/pip-req.txt /opt/sources/pip-req.txt

# SM: Install Odoo python dependencies
RUN pip install -r /opt/sources/pip-req.txt

# SM: Upgrade pillow to allow JPEG resize operations (used by demo data)
RUN pip install -i --upgrade pillow

# must unzip this package to make it visible as an odoo external dependency
RUN easy_install -UZ py3o.template

# install wkhtmltopdf based on QT5
ADD http://download.gna.org/wkhtmltopdf/0.12/0.12.2.1/wkhtmltox-0.12.2.1_linux-trusty-amd64.deb /opt/sources/wkhtmltox.deb
RUN dpkg -i /opt/sources/wkhtmltox.deb

# create the odoo user
RUN adduser --home=/opt/odoo --disabled-password --gecos "" --shell=/bin/bash odoo

# changing user is required by openerp which won't start with root
# makes the container more unlikely to be unwillingly changed in interactive mode
USER odoo

RUN /bin/bash -c "mkdir -p /opt/odoo/{bin,etc,sources/odoo,additional_addons,data}"
RUN /bin/bash -c "mkdir -p /opt/odoo/var/{run,log,egg-cache}"

# SM: Add Odoo OCB sources
WORKDIR /opt/odoo/sources
RUN git clone https://github.com/OCA/OCB.git -b 7.0 odoo

# Execution environment
USER 0
ADD sources/odoo.conf /opt/sources/odoo.conf
WORKDIR /app
VOLUME ["/opt/odoo/var", "/opt/odoo/etc", "/opt/odoo/additional_addons", "/opt/odoo/data"]
# Set the default entrypoint (non overridable) to run when starting the container
ENTRYPOINT ["/app/bin/boot"]
CMD ["help"]
# Expose the odoo ports (for linked containers)
EXPOSE 8069 8072
ADD bin /app/bin/
