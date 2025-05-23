FROM tomcat:latest

# Copy WAR into Tomcat webapps directory
COPY ./webapp.war /usr/local/tomcat/webapps

# Optional: Copy default webapps (if required)
RUN cp -r /usr/local/tomcat/webapps.dist/* /usr/local/tomcat/webapps

