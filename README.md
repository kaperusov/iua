# Интеграционный узел Адаптера (ИУА) СМЭВ 3

## Подгатовка системы

**1. Задаем имена узлам. Для этого выполняем команды на соответствующих серверах:**

```shell
hostnamectl set-hostname smev-server-master.smk-systems.ru
hostnamectl set-hostname smev-server-worker-01.smk-systems.ru
hostnamectl set-hostname smev-server-worker-02.smk-systems.ru
```

Необходимо, чтобы наши серверы были доступны по заданным именам.
Для этого необходимо на сервере DNS добавить соответствующие А-записи. 
Или на каждом сервере отредактировать файл `/etc/hosts`.

**2. Устанавливаем необходимые пакеты:**

```shell
apt update && apt upgrade
apt install -y vim curl git apt-transport-https iptables-persistent
```

> В процессе установки iptables-persistent может запросить подтверждение сохранить правила брандмауэра — отказываемся.

**3. Отключаем файл подкачки. С ним Kubernetes не запустится:**

```shell
sed -i '/swap/s/^/#/' /etc/fstab
swapoff -a
```

**4. Загружаем дополнительные модули ядра:**

```shell
cat <<EOF > /etc/modules-load.d/k8s.conf
br_netfilter
overlay
EOF
```
> модуль br_netfilter расширяет возможности netfilter 
([подробнее](https://ebtables.netfilter.org/documentation/bridge-nf.html)); 
overlay необходим для Docker.

Загрузим модули в ядро и убедимся, что они работают:

```shell
modprobe br_netfilter && modprobe overlay
lsmod | egrep "br_netfilter|overlay"
```

Мы должны увидеть что-то на подобие:

```shell
overlay               114688  10
br_netfilter           28672  0
bridge                176128  1 br_netfilter
```

**5. Ещё немного конфигурации:**

Создаем конфигурационный файл: 
```shell
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
```

> **net.bridge.bridge-nf-call-iptables** контролирует возможность обработки трафика через bridge в netfilter.
> В нашем примере мы разрешаем данную обработку для IPv4 и IPv6.

Применяем параметры командой:

```shell
sysctl --system
```

### Установка Docker

Детали установки [см. в оффициальной документации](https://docs.docker.com/desktop/install/linux-install/)

#### Настройка Docker daemon

Для корректной работы, нам необходимо создать (или отредактировать) конфигурационный файл 
`/etc/docker/daemon.json` следующего содержания:

```json
{
    "insecure-registries":["my-docker-registry.ru:5000"],
    "bip": "10.200.0.1/24",
    "default-address-pools":[
        { "base":"10.201.0.0/16", "size":24 },
        { "base":"10.202.0.0/16", "size":24 },
        { "base":"10.203.0.0/16", "size":24 },
        { "base":"10.205.0.0/16", "size":24 }
    ],
    "exec-opts": ["native.cgroupdriver=systemd"],
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m"
    },
    "storage-driver": "overlay2",
    "storage-opts": [
        "overlay2.override_kernel_check=true"
    ]
}
```

Здесь следуюет обратить внимание на такие параметры как: 

**insecure-registries**: разрешаем докеру обращаться к [приватному репозиторию](#DockerPrivateRegistry) образов
по указанному адресу без сертификата и аутентификации. 

> ВНИМАНИЕ! Эта процедура настраивает Docker на полное игнорирование безопасности вашего реестра. 
Это очень небезопасно, используйте это решение только для работы внутри изолированного контура. 
[Читать подробнее.](https://docs.docker.com/registry/insecure/) 

**bip** и **default-address-pools**: позволяет указать докуру в каком адресном пространстве он может создавать свои сетевые интерфейсы.
Важным здесь является то, что по-умолчанию Docker создаёт подсети в пространстве начиная с 172.17.0.0/16, а продуктивный адрес СМЭВ - это 172.20.3.12 ... 
Из-за чего потенциально возможен конфликт, когда поднятый докером сетевой интерфейс заглушает доступ к этому адресу.

Настройка **cgroupdriver** она должна быть выставлена в значение `systemd`. В противном случае, при создании кластера Kubernetes выдаст предупреждение. 
Хоть на возможность работы последнего это не влияет, мы постараемся выполнить развертывание без ошибок и предупреждений со стороны системы.

**log-driver** и **log-opts**: определяет формат хранения логов и их максимальный размер на хостовой машине. 
Найти эти файлы можно будет по следующей схеме: `/var/lib/docker/containers/<CONTAINER_ID>/<CONTAINER_ID>-json.log`

Опции **storage-driver** и **storage-opts** управляют тем, как докер образы и контейнеры хранятся и управляются на вашем хосте Docker.
overlay2 является предпочтительным драйвером хранилища для всех поддерживаемых в настоящее время дистрибутивов Linux и не требует 
дополнительной настройки. [Читать подробнее.](https://docs.docker.com/storage/storagedriver/)

После сохранения файла необходимо перезапустить сервис docker, предварительно сказав ему перечитать конфигурацию:

```shell
systemctl reload docker
systemctl restart docker
```

### Установка NFS-сервера (нужен для работы PersistentVolumes)

На мастер-ноде выполнить следующие действия:

<details><summary>debian</summary>

```bash
apt install -y nfs-kernel-server

mkdir -p /nfsshare/keys /nfsshare/basket /nfsshare/file

cat <<EOF > /etc/exports
/nfsshare/keys     *(rw,sync,no_subtree_check,no_root_squash)
/nfsshare/basket   *(rw,sync,no_subtree_check,no_root_squash)
/nfsshare/file     *(rw,sync,no_subtree_check,no_root_squash)
EOF

exportfs -ra

systemctl enable nfs-kernel-server.service
systemctl restart nfs-kernel-server.service

chmod -R 755 /nfsshare/
```

</details>

<details><summary>CentOS</summary>


```bash
yum install -y nfs-utils 

# Создаем каталоги для NFS 
mkdir -p /nfsshare/keys /nfsshare/basket /nfsshare/file

# Прописываем в файл /etc/exports, каталог, ip-подсеть и параметры шары: 
cat <<EOF > /etc/exports
/nfsshare/keys     *(rw,sync,no_subtree_check,no_root_squash)
/nfsshare/basket   *(rw,sync,no_subtree_check,no_root_squash)
/nfsshare/file     *(rw,sync,no_subtree_check,no_root_squash)
EOF
exportfs -ra

# после выполнения данной команды убеждаемся, что шара активна 
exportfs

# Если есть firewall то пишем правила:
firewall-cmd --permanent --zone=public --add-service=nfs 
firewall-cmd --permanent --zone=public --add-service=mountd 
firewall-cmd --permanent --zone=public --add-service=rpc-bind 
firewall-cmd --reload

# Запуск:
systemctl enable rpcbind nfs-server
systemctl start rpcbind nfs-server
```

On the client, we can install NFS as follows (this is actually the same as on the server):

```bash
yum -y install nfs-utils
```
</details>



### Создание docker private registry 

Есть два способа создания репозитория: 

<details><summary>Через docker-compose</summary>

Для установки необходимых пакетов и запуска сервиса нужно выполнить следующие команды: 

```shell
# устанавливаем htpasswd 
#  -- в Debian из пакета apache2-utils:
sudo apt install -y apache2-utils

#  -- в CentOS из пакета httpd-tools:
yum install -y httpd-tools

# задаём пароль для пользователя, который будет работать с репозиторием образов
mkdir -p /var/lib/registry/auth /var/lib/registry/data
htpasswd -Bc /var/lib/registry/auth/registry.password <DOCKER_USER>

# запукаем сервис:
docker-compose -f docker/registry/docker-compose.yml up -d 
```

</details>

<details><summary>Через docker-distribution</summary>

```shell
# устанавливаем пакет `docker-distribution` на нашу ЭВМ:
yum install -y docker-distribution

# устанавливаем htpasswd из пакета httpd-tools
yum install -y httpd-tools

# задаём пароль для пользователя, который будет работать с репозиторием образов
mkdir -p /var/lib/registry/auth /var/lib/registry/data
htpasswd -B -c /var/lib/registry/auth/registry.password <DOCKER_USER>

# копируем конфигурационный файл docker-distribution 
cp docker/registry/docker-distribution.config.yml /etc/docker-distribution/registry/config.yml

# запукаем сервис:
systemctl enable docker-distribution
systemctl start docker-distribution
systemctl status docker-distribution
```
</details>

В обоих случаях нужно указать `DOCKER_USER` и задать ему пароль.
Это пользователь, под которым можно будет делать push и pull в docker private registry.


Теперь нам нужно настроить доступ к этому нашему docker private registry. 
Для этого выполним команду: 

```shell
docker login ${DOCKER_HOSTNAME}:${PORT} --username ${DOCKER_USER}
```

где 
* *DOCKER_HOSTNAME* -- это адрес расположения докер репозитория 
* *PORT* -- порт, на котором работает репозиторий
* *DOCKER_USER* -- имя пользователя в репозитории

После выполнения этой команды в домашней директории пользователя появится файл 
`~/.docker/config.json`, примерно следующего содержания:

```json
{
	"auths": {
		"my-docker-registry.ru:5000": {
			"auth": "ZG9...DU2"
		}
	}
}
```

На основе этого файла нам необходимо создать Kubernetes Secret:

```bash
kubectl create secret generic regcred \
    --from-file=.dockerconfigjson=$(readlink -f ~/.docker/config.json) \
    --type=kubernetes.io/dockerconfigjson
```


### Загрузка Docker образов в docker private registry

В папке utils есть sh скрпит, который поможет выполнить скачивание официальных образов ИУА с сайта минцифры
и загрузить их в наш docker registry. Для этого нужно восспользоваться командами: 

```shell
./utils/iua-images.sh --download [VERSION]
./utils/iua-images.sh --load [DIR]
./utils/iua-images.sh --push
```





## Установка Kubernetes через kubeadm

<details><summary>Debian/Ubuntu</summary>

Установку необходимых компонентов выполним из репозитория:

```shell
cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

apt update && apt install kubelet kubeadm kubectl
```

* где:
    * **kubelet** — сервис, который запускается и работает на каждом узле кластера. 
    Следит за работоспособностью подов.
    * **kubeadm** — утилита для управления кластером Kubernetes.
    * **kubectl** — утилита для отправки команд кластеру Kubernetes.

Нормальная работа кластера сильно зависит от версии установленных пакетов. 
Поэтому бесконтрольное их обновление может привести к потере работоспособности всей системы. 
Чтобы этого не произошло, запрещаем обновление установленных компонентов:

```shell
apt-mark hold kubelet kubeadm kubectl
```
</details>

<details><summary>CentOS 7</summary>

ВАЖНО! От версии к версии могут быть какие-то нестыковки и необжиданное поведение. 
Данная инструкция проводилась на версии kubernetes 1.23.3 

Известно, что с версией 1.24.0 возникли проблемы с выгрузкой докеров на рабочие ноды... 

Добавляем репозиторий из котрого будет устанавливаться Kubernetes:

```shell
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
#repo_gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
```

Запускаем установку необходимых компонентов:

```shell
yum install -y containernetworking-plugins
yum install -y kubelet kubeadm kubectl
systemctl enable kubelet
systemctl start kubelet
```
</details>


Установка завершена - можно запустить команду:

```shell
kubectl version --client
```

## Создание кластера

По-отдельности, рассмотрим процесс настройки мастер ноды (control-plane) и присоединения к ней двух рабочих нод (worker).

### Настройка control-plane (мастер ноды)

Выполняем команду на мастер ноде:

```
kubeadm init --pod-network-cidr=10.244.0.0/16
```

Данная команда выполнит начальную настройку и подготовку основного узла кластера. 
Ключ `--pod-network-cidr` задает адрес внутренней подсети для нашего кластера. 

> И здесь **ВНИМАНИЕ!** 
> 
> Указанный адрес понадобиться чуть дальше, при создании CNI. 
> Нужно будет проследить, чтобы они были в одной подсети.

По завершении команды мы увидим что-то наподобие:

```
[...omitted...]

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 10.128.37.227:6443 --token 8x6pdz.cgsih1j6vypha7sq \
	--discovery-token-ca-cert-hash sha256:74159ee23103ba9e286c95fb6c0140c3c63b128dfb72bf0c10b156768c45b5c5 
```

Данную команду нужно вводить на worker нодах, чтобы присоединить их к нашему кластеру. 
Можно её сохранить, но можно всегда сгенерировать по-новой, для добавления новых worker-нод в любой моммент.

В окружении пользователя создаем переменную `KUBECONFIG`, с помощью которой будет указан путь до файла конфигурации kubernetes.
Для этого нужно отредактировать файл `/etc/environment`

```shell
echo 'export KUBECONFIG=/etc/kubernetes/admin.conf' >> /etc/environment
source /etc/environment
```

Посмотреть список узлов кластера можно командой: `kubectl get nodes`

На данном этапе мы должны увидеть только мастер ноду:

```
[root@smev-server-master charts]# kubectl get nodes
NAME                    STATUS   ROLES                  AGE   VERSION
smev-server-master      Ready    control-plane,master   25h   v1.23.17
```


### CNI

Чтобы завершить настройку, необходимо установить 
[CNI (Container Networking Interface)](https://www.cni.dev/plugins/current/). 
[Спецификации](https://github.com/containernetworking/cni/blob/master/SPEC.md)

В нашем случае использовался [flannel](https://github.com/flannel-io/flannel):

```shell
# скачиваем последню версию (если это необходимо)
curl -k https://raw.githubusercontent.com/flannel-io/flannel/v0.16.1/Documentation/kube-flannel.yml \
    --output cni/flannel-0.16.1.yaml
```

Внутри файла нужно проверить, что указанная подсеть совпадает с той, которую мы
указывали в ключе `--pod-network-cidr=10.244.0.0/16`, когда инициализировали класстер:

Сравнить CIDR нашего кластера и flannel можно командами:

```bash 
kubectl cluster-info dump | grep -m 1 cluster-cidr
grep -w 'Network' cni/flannel-0.16.1.yaml
```

При необходимости поправим значение в файле:
```shell
sed -i "s~$old_ip~$new_ip~" flannel-0.16.1.yaml
```

Применяем:
```shell
kubectl apply -f cni/flannel-0.16.1.yaml
```

Проверть, что всё завелось как надо можно командой:

```bash
kubectl -n kube-system get pod
```

Если ошибок нет и все поды назодятся в статусе `Running`, то можно считать что 
узел управления кластером готов к работе.


### Настройка рабочи нод (worker)

Мы можем использовать команду для присоединения рабочего узла, 
которую мы получили после инициализации мастер ноды или вводим (на первом узле):

```shell
kubeadm token create --print-join-command
```

Данная команда покажет нам запрос на присоединения новой ноды к кластеру, например:

```
kubeadm join 192.168.0.15:6443 --token f7sihu.wmgzwxkvbr8500al \
    --discovery-token-ca-cert-hash sha256:6746f66b2197ef496192c9e240b31275747734cf74057e04409c33b1ad280321
```

Копируем его и применяем на рабочих узлах. После завершения работы команды, мы должны увидеть:

```
Run 'kubectl get nodes' on the control-plane to see this node join the cluster.
```

Теперь если на мастер ноде ввести команду: `kubectl get nodes`

Мы должны увидеть что-то вроде этого: 
```
NAME                    STATUS   ROLES                  AGE   VERSION
smev-server-master      Ready    control-plane,master   25h   v1.23.17
smev-server-worker-01   Ready    <none>                 25h   v1.23.17
smev-server-worker-02   Ready    <none>                 25h   v1.23.17
```



## Развёртывание docker-образов ИУА в Kubernetes


Развертывание компонентов системы производится командами, в которых передаются ранее заполненные
файлы конфигурации со средозависимыми переменными.  

В приведенных командах:
* `$(ENV)` - название среды окружения, с установленными переменными. В проекте есть пример окружения - sample (sample.yml и sample/). 
На его основе нужно создать свои файлы и использовать их для рендеринга yaml скриптов. 
* `$(NAMESPACE)` - целевое пространство имен в Kubernetes. 


В первую очередь устанавливается чарт `pvc`, который добавит необходимые Persistent Volume и Persistent Volume Claim. 
В зависимости от настроек окружения Persistent Volume может быть настроен по разному. 
В нашем случае, мы будем использовать заранее подготовленный NFS сервер:

```shell
# --- pvc with nfs
	helm install pvc charts/pvc/ -f $(ENV).yml -f pvc/nfs.yaml -n $(NAMESPACE)
```

Далее с помощью команд устанавливаются остальные модули приложения:

```shell
# --- pvc with nfs
helm install pvc charts/pvc/ -f charts/env/$(ENV).yml -f pvc/nfs.yaml -n $(NAMESPACE)

# --- storage-tool-job
helm install storage-tool-job charts/storage-tool-job/ -f charts/env/$(ENV).yml -f charts/env/$(ENV)/storage-tool-job.yml -n $(NAMESPACE)

# --- amqp-integration-adapter
helm install amqp-integration-adapter charts/amqp-integration-adapter/ -f charts/env/$(ENV).yml -f charts/env/$(ENV)/amqp-integration-adapter.yml -n $(NAMESPACE)

# --- batch-adapter 
helm install batch-adapter charts/batch-adapter/ -f charts/env/$(ENV).yml -f charts/env/$(ENV)/batch-adapter.yml -n $(NAMESPACE)

# --- db-integration-adapter
helm install db-integration-adapter charts/db-integration-adapter/ -f charts/env/$(ENV).yml -f charts/env/$(ENV)/db-integration-adapter.yml -n $(NAMESPACE)

# --- file-integration-adapter
helm install file-integration-adapter charts/file-integration-adapter/ -f charts/env/$(ENV).yml -f charts/env/$(ENV)/file-integration-adapter.yml -n $(NAMESPACE)

# --- plugin-integration-adapter
helm install plugin-integration-adapter charts/plugin-integration-adapter/ -f charts/env/$(ENV).yml -f charts/env/$(ENV)/plugin-integration-adapter.yml -n default

# --- push-notifications-adapter
helm install push-notifications-adapter charts/push-notifications-adapter/ -f charts/env/$(ENV).yml -f charts/env/$(ENV)/push-notifications-adapter.yml -n $(NAMESPACE)

# --- scheduler-adapter
helm install scheduler-adapter charts/scheduler-adapter/ -f charts/env/$(ENV).yml -f charts/env/$(ENV)/scheduler-adapter.yml -n $(NAMESPACE)

# --- smev-http-adapter
helm install smev-http-adapter charts/smev-http-adapter/ -f charts/env/$(ENV).yml -f charts/env/$(ENV)/smev-http-adapter.yml -n $(NAMESPACE)

# --- statistics-adapter
helm install statistics-adapter charts/statistics-adapter/ -f charts/env/$(ENV).yml -f charts/env/$(ENV)/statistics-adapter.yml -n $(NAMESPACE)

# --- ws-integration-adapter
helm install ws-integration-adapter charts/ws-integration-adapter/ -f charts/env/$(ENV).yml -f charts/env/$(ENV)/ws-integration-adapter.yml -n $(NAMESPACE)

# --- ui-adapter
helm install ui-adapter charts/ui-adapter/ -f charts/env/$(ENV).yml -f charts/env/$(ENV)/ui-adapter.yml -n $(NAMESPACE)

# --- inner-integration-adapter
helm install inner-integration-adapter charts/inner-integration-adapter/ -f charts/env/$(ENV).yml -f charts/env/$(ENV)/inner-integration-adapter.yml -n $(NAMESPACE)

# --- smev-front
helm install smev-front charts/smev-front/ -f charts/env/$(ENV).yml -f charts/env/$(ENV)/smev-front.yml -n $(NAMESPACE)
```


Если вы очень торопитесь, то можно восспользоваться командой make:

```shell
make install -e ENV=prod -e NAMESPACE=iua
```

### Ingress Controller

Для доступа к web-интерфейсу ИУА в кластере kubernetes должен быть развёрнут Ingress-контроллер и сконфигурирован Loadbalancer

**1. В качестве LoadBalancer возьмём MetallLB:**

[via. metallb.universe.tf/installation](https://metallb.universe.tf/installation/)

```shell
helm repo add metallb https://metallb.github.io/metallb
helm install metallb metallb/metallb --namespace metallb-system --create-namespace
```

Добавим к нему ARP конфигурацию с пулом IP адресов: 

Пример `loadbalancer/metallb-address-pool.yaml` файла: 

```yaml
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default
  namespace: metallb-system
spec:
  addresses:
  - 192.168.2.200-192.168.2.220
  autoAssign: true

---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
spec:
  ipAddressPools:
    - default
```

При необходимости правим секцию `spec.addresses` и применяем файл: 
```shell
kubectl apply -f loadbalancer/metallb-address-pool.yaml
```


**2. В качестве Ingress-контроллера возьмём ingress-nginx:**

```shell
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm repo list

# 
helm upgrade --install iua-ingress ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace
```

Проверяем, что всё установилось `kubectl get svc -n ingress-nginx`:

```
NAME                                             TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)                      AGE
iua-ingress-ingress-nginx-controller             LoadBalancer   10.105.246.82   192.168.2.209   80:31652/TCP,443:32111/TCP   14h
iua-ingress-ingress-nginx-controller-admission   ClusterIP      10.96.190.144   <none>          443/TCP                      14h
```


**3. Применим наш ingress kind для маршрутизации входящего трафика на внутренние сервисы:**

```shell
kubectl apply -f iua-ingress/ingress.yaml
```


## Развёртывание RabbitMQ

```shell
helm repo add bitnami https://charts.bitnami.com/bitnami
helm update 

helm upgrade --install rabbitmq -f values.yaml bitnami/rabbitmq --namespace rabbitmq --create-namespace
```

Примерное сожержание файла `values.yaml`:
```yaml
auth:
  username: user
  password: SuperSecretPassw0d!

ingress:
  enabled: true
  ingressClassName: nginx
  path: /
  pathType: Prefix
  hostname: rabbitmq.smev-server-master.smk-systems.ru
```
Полное описание можно посмотреть [по ссылке](https://github.com/bitnami/charts/blob/main/bitnami/rabbitmq/values.yaml).

В результате должны получить примерно следующий вывод: 
```
Credentials:
    echo "Username      : user"
    echo "Password      : $(kubectl get secret --namespace rabbitmq rabbitmq -o jsonpath="{.data.rabbitmq-password}" | base64 -d)"
    echo "ErLang Cookie : $(kubectl get secret --namespace rabbitmq rabbitmq -o jsonpath="{.data.rabbitmq-erlang-cookie}" | base64 -d)"

Note that the credentials are saved in persistent volume claims and will not be changed upon upgrade or reinstallation unless the persistent volume claim has been deleted. If this is not the first installation of this chart, the credentials may not be valid.
This is applicable when no passwords are set and therefore the random password is autogenerated. In case of using a fixed password, you should specify it when upgrading.
More information about the credentials may be found at https://docs.bitnami.com/general/how-to/troubleshoot-helm-chart-issues/#credential-errors-while-upgrading-chart-releases.

RabbitMQ can be accessed within the cluster on port 5672 at rabbitmq.rabbitmq.svc.cluster.local

To access for outside the cluster, perform the following steps:

To Access the RabbitMQ AMQP port:

    echo "URL : amqp://127.0.0.1:5672/"
    kubectl port-forward --namespace rabbitmq svc/rabbitmq 5672:5672

To Access the RabbitMQ Management interface:

    echo "URL : http://127.0.0.1:15672/"
    kubectl port-forward --namespace rabbitmq svc/rabbitmq 15672:15672

```



