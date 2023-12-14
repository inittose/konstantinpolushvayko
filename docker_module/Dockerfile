# Выбираем образ Ubuntu и
# преписываем ему этап (stage) build.
# Чтобы остановиться на конкретном этапе
# нужно прописать:
# docker build --target build -t resume .
FROM ubuntu:22.04 AS build

# Переменные Dockerfile
ARG YQ_VERSION=v4.40.5
ARG YQ_BINARY=yq_linux_amd64
ARG TASK_VERSION=v3.32.0
ARG TASK_BINARY=task_linux_amd64.tar.gz

# Скачиваем нужные пакеты (утилиты),
# чтобы собрать проект (во время этого процесса
# будут создаваться новые слои в контейнере)
RUN apt-get update &&  \
    apt-get install -y \
      libfontconfig1 \
      libxtst6 \
      rubygems \
      wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN gem install yaml-cv
RUN wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${YQ_BINARY} -O /usr/bin/yq \
    && chmod +x /usr/bin/yq

RUN wget -O- https://github.com/go-task/task/releases/download/${TASK_VERSION}/${TASK_BINARY} \
    | tar xz -C /usr/bin


# Выбираем рабочую папку
WORKDIR /app

# Копируем нужные файлы в контейнер
COPY .env .
COPY src/ src/
COPY scripts/ scripts/
COPY Taskfile.yaml .

# Собираем наш проект
RUN task build

# Используя многоэтапную сборку (multi-stage builds),
# выбираем новый образ, чтобы скопировать туда cv.html
FROM busybox AS release

WORKDIR /app

# --from=build означает, что мы будем копировать
# файлы из контейнера этапа build
COPY --from=build /app/build/cv.html /app/
