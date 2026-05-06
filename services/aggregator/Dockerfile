FROM ubuntu:22.04
ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt update && apt install -y \
    git \
    python3 \
    python3-pip \
    wget \
    ca-certificates 

#ADD nrel_root.pem /usr/local/share/ca-certificates/nrel_root.crt 
#ADD nrel_xca1.pem /usr/local/share/ca-certificates/nrel_xca1.crt

RUN update-ca-certificates 2>/dev/null || true

WORKDIR /usr/src/app

ADD *.py ./
ADD requirements.txt ./ /usr/src/app/

RUN  pip3 install -r requirements.txt

CMD ["python3", "aggregator.py"]
