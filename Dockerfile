# MySQL with Mroonga environment for CentOS 6.x
#
# VERSION       0.0.1

FROM centos
MAINTAINER Kentaro Yoshida "https://github.com/y-ken"

ENV MROONGA_VERSION mroonga-4.00-2
ENV HOME /root

# setup timezone
RUN echo 'ZONE="Asia/Tokyo"' > /etc/sysconfig/clock
RUN echo 'UTC="false"' >> /etc/sysconfig/clock
RUN echo 'ARC="false"' >> /etc/sysconfig/clock
RUN cp -p /usr/share/zoneinfo/Asia/Tokyo /etc/localtime 

# download package
WORKDIR /usr/local/src
RUN wget -q https://github.com/y-ken/package/releases/download/${MROONGA_VERSION}/${MROONGA_VERSION}.zip -O ${MROONGA_VERSION}.zip

# extract package
RUN yum -y -q install unzip
RUN unzip -q ${MROONGA_VERSION}.zip

# replace mysql-libs to MySQL-shared-compat
RUN yum -y -q install ${MROONGA_VERSION}/MySQL-shared-compat-*.rpm

# install MySQL
RUN yum -y -q install \
  ${MROONGA_VERSION}/MySQL-client-5.6.*.rpm ${MROONGA_VERSION}/MySQL-devel-5.6.*.rpm \
  ${MROONGA_VERSION}/MySQL-server-5.6.*.rpm ${MROONGA_VERSION}/MySQL-shared-5.6.*.rpm \
  /etc/init.d/mysql stop

# setup mysql password
RUN /etc/init.d/mysql start && sleep 2 && \
  MYSQL_PWD=$(tail -2 /root/.mysql_secret | awk -F ': ' '{print $2}') \
  mysqladmin -uroot  password "" && \
  mysql -uroot -e 'update user SET Password="" where User="root"' mysql && \
  mysql -uroot -e "grant all privileges on *.* to root@'%';" && \
  /etc/init.d/mysql stop

# install mroonga
RUN /etc/init.d/mysql start && sleep 2 && \
  yum -y -q install ${MROONGA_VERSION}/groonga*.rpm \
  ${MROONGA_VERSION}/mecab*.rpm ${MROONGA_VERSION}/mysql56-mroonga*.rpm \
  /etc/init.d/mysql stop

# configure mysql
ADD my.cnf /etc/my.cnf

# configure ib_buffer_pool
RUN touch /var/lib/mysql/ib_buffer_pool
RUN chown mysql:mysql /var/lib/mysql/ib_buffer_pool
RUN chmod 660 /var/lib/mysql/ib_buffer_pool

# configure logfile
RUN mkdir /var/log/mysql/
RUN touch /var/log/mysql/mysqld.log \
  /var/log/mysql/mysql-general.log \
  /var/log/mysql/mysql-slow.log
RUN chown -R mysql:root /var/log/mysql/
RUN chmod 664 /var/log/mysql/*
ADD logrotate-mysql.conf /etc/logrotate.d/mysql

EXPOSE 3306
CMD ["/usr/bin/mysqld_safe"]
