# Практическая работа №3 "Технологии контейнеризации"
## Тема: "Модуль Docker"

- Подготовил: **Полушвайко Константин Николаевич**
- Место учебы: ТУСУР, ФВС, КСУП, группа 582-1

## Задание 3.1 Docker
1. Создайте собственный форк репозитория с примером.
1. Добавьте Dockerfile для сборки следующих образов.
    1. **Образ 1**, который содержит:
        - Необходимые файлы и утилиты для осуществления сборки версии резюме внутри контейнера.
        - Использует в качестве основной команды `task` и позволяет выполнять автоматизированные задачи при запуске контейнера.
        - При запуске контейнера без дополнительных агрументов, выполняет задачу сборки.
    1. **Образ 2**, который содержит только собранную версию резюме в формате HTML и экспортирует её для использования в других контейнерах.
1. Автоматизируйте задачу сборки образов.
1. Оптимизируйте процесс сборки образов.


## Ход работы
Для начала создадим `Dockerfile` который будет содержать все наши инструкции. Определим задачи:
- Изначальный образ должен поддерживать все инструменты сборки резюме из 2 практики;
- Нужно установить все необходимые пакеты и утилиты в образ;
- Непосредственно сборка резюме.

Начнем писать наш `Dockerfile`. В качестве базового образа выберем `ubuntu:22.04`:
```Dockerfile
FROM ubuntu:22.04
```

Далее для удобства определим переменные при помощи оператора `ARG`:
```Dockerfile
ARG YQ_VERSION=v4.40.5
ARG YQ_BINARY=yq_linux_amd64
ARG TASK_VERSION=v3.32.0
ARG TASK_BINARY=task_linux_amd64.tar.gz
```

Чтобы установить все пакеты воспользуемся инструкцией `RUN`:
```Dockerfile
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
```

Определим рабочую директорию:
```Dockerfile
WORKDIR /app
```

Скопируем все скрипты, исходные файлы в слой образа:
```Dockerfile
COPY .env .env
COPY src/ src/
COPY scripts/ scripts/
COPY Taskfile.yaml Taskfile.yaml
```

Теперь мы можем собрать наш проект:
```Dockerfile
RUN task build
```

Первый образ готов, теперь мы можем его собрать и запустить:
```bash
docker image build -t resume .
docker run -it --rm resume
```

Если мы введем эти команды, то выведется консоль контейнера, который содержит все наши исходные данные и собранные файлы.

---

Далее нам необходимо реализовать 2-й образ, который будет принимать `cv.html`. Чтобы упростить нашу задачу, воспользуемся многоэтапной сборкой (**multi-stage build**) в `Dockerfile`. Изменим `FROM ubuntu:22.04` из первой части на:
```Dockerfile
FROM ubuntu:22.04 AS build
```

Мы определили этап с `ubuntu` как этап сборки, теперь мы можем создать второй этап, используя базовый образ `busybox`, и назовем его `release`:
```Dockerfile
FROM busybox AS release
```

> **Почему `busybox`?** Потому что это очень легкий образ, который
>может предназначаться для многих несложных задач, в нашем случае
>хранение cv.html.

Сразу можно определить рабочую директорию для удобства работы:
```Dockerfile
WORKDIR /app
```

Теперь, когда у нас есть четкое разделение на этапы, мы можем обратиться к прошлому этапу `build`, чтобы скопировать оттуда собранный файл `cv.html`:
```Dockerfile
COPY --from=build /app/build/cv.html .
```

Чтобы собрать образ и запустить его можно использовать код, который мы уже писали для сборки первого образа:
```bash
docker image build -t resume .
docker run -it --rm resume
```

Но тогда соберутся все этапы. Чтобы этого избежать можно применить `--target`. Пример сборки **предыдущего** этапа:
```bash
docker image build --target build -t resume .
docker run -it --rm resume
```

---

Теперь, когда мы разобрались с образами можем переходить к автоматизации через `task`. Определим следующие задачи в `taskfile`:
- `docker-build`
- `docker-release`
- `docker-run-build`
- `docker-run-release`

В `taskfile.yaml` это будет выглядеть так:
```yaml
docker-build:
  docker build --target build -t resume .

docker-release:
  docker build --target release -t resume .

docker-run-build:
  deps:
    - docker-build
  cmds:
    - docker run -it --rm resume

docker-run-release:
  deps:
    - docker-release
  cmds:
    - docker run -it --rm resume
```

Пример сборки и запуска через `task`:
```bash
task docker-run-build
```

**Задача 3.1 выполенена**


## Задание 3.2 Docker-compose
1. Используйте [nginx](https://nginx.org/ru/) в качеcтве веб-сервера:
    - nginx выполняется в контейнере и использует [официальный образ](https://hub.docker.com/_/nginx);
    - конфигурационный файл nginx хранится локально;
    - используется только протокол HTTP;
    - вывод логов nginx доступен через команду `docker logs`;
1. Реализуйте возможность сборки образа приложения через docker-compose.
1. Реализуйте команды запуска и остановки приложения средствами локальной автоматизации (Taskfile).

## Ход работы
Для начала создаем файл `docker-compose.yml`. Начнем его заполнять:
```yaml
version: '3'

services:
  resume_builder:
    build: .
```

Теперь, если мы поднимем `docker-compose` у нас соберется новый образ и сразу же запустится. Для запуска используем:
```bash
docker-compose up
```

Далее, мы научились собирать и запускать контейнеры, нужно запустить nginx с нашим резюме. Попробуем запустить `nginx`:
```yaml
  nginx:
    image: nginx
    ports:
      - "8080:80"
```

При запуске `docker-compose up` можно зайти на `localhost:8080` и увидеть:
![nginx](images/nginx.png)

Осталось связать вывод из `resume_builder` и `nginx`. Чтобы это сделать создадим пустой том `resume` в `docker-compose.yml`, в котором мы будем хранить резюме в `.html`:
```yaml
volumes:
  resume:
```

Надо добавить в этот том наше резюме. Вот как будет выглядеть `resume_builder`:
```yaml
  resume_builder:
    build: .
    volumes:
      - resume:/app
```

Тем временем в `nginx` надо добавить зависимость от `resume_builder` и монтировать резюме в `/usr/share/nginx/html`:
```yaml
  nginx:
    depends_on:
      - resume_builder
    image: nginx
    volumes:
      - resume:/usr/share/nginx/html
    ports:
      - "8080:80"
```

Запустим проект: `docker-compose up -d`. В `localhost:8080` можно увидеть:
![resume](images/resume.png)

Чтобы остановить контейнеры вводим в консоль:
```bash
docker-compose stop
```

**Задача 3.2 выполенена**
