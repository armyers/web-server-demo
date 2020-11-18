FROM python:latest

RUN mkdir -p /opt/web-server

ADD ./web-server/web-server.py /opt/web-server/

CMD ["python", "/opt/web-server/web-server.py"]
