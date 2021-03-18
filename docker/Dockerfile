FROM debian:10 as final
RUN apt-get update
RUN apt-get install -y --no-install-recommends \
    iperf3=3.6-2 \
    netsniff-ng=0.6.5-1 \
    iptables

COPY entrypoint.sh  /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh
EXPOSE 5201
ENTRYPOINT ["/app/entrypoint.sh"]



FROM final as dev
RUN apt-get update 
RUN apt-get install -y --no-install-recommends \
    nano=3.2-3 \
    screen=4.6.2-3 \
    tcpdump=4.9.3-1~deb10u1
