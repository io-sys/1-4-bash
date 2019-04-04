### 1+2) Скрипт watchdog с перезагрузкой процесса/сервиса; watchdog с отсылкой емэйла
Файлы в репозитории: `watchdog.sh`; `var-spool-cron-root`

**watchdog.sh** скрипт, который запускается каждую минуту по `cron` (`/var/spool/cron/root` файл в репозитории `var-spool-cron-root`).
Как работает скрипт, логика:
1) Когда сервис остановлен, скрипт его попытается запустить, если неудача запуска, тогда отправляется `e-mail` с предупрежденим `root`(-у).
2) Если сервис работает и всё в порядке, скрипт напишет `$1 is Active`, когда скрипт запущен вручную, по `cron` процес проверки пройдет тихо.

> **cat /opt/watchdog.sh**
```php
Скрипт #!/usr/bin/env bash  lines () {
pid1=0
serv=$1

if [[ -z $serv ]]
then
  echo -e "\e[31m No one parameters got the script. Service name is empty.\e[0m"
  return 0
fi

pid1=$(pgrep $serv)        # $1=nginx PID1 PID2

if [[ -z $pid1 ]]
then
   echo -e "\e[31mService $serv is down\e[32m and now will be started.\e[0m"
   service $serv start
else
   echo -e "Service $serv: \e[32mis Active.\e[0m"
fi
}

lines $1
```
> **cron**
```php
crontab -l
* * * * *  bash /opt/watchdog.sh nginx >/tmp/cron1.log 2>&1 || echo "Failed" | mail -s "nginx doesnt work" root
```

###### Пример: перезапуск или проверка статуса сервиса nginx
watchdog.sh
```php
 ./watchdog.sh nginx
```
 Имя сервиса задается в первом параметре.
```php
[root@linuxbash opt]# ./watchdog.sh
No one parameters got the script. Service name empty.
[root@linuxbash opt]# ./watchdog.sh nginx
Service nginx: is Active.
```
Тест, остановим nginx и запустим скрипт.
```php
[root@linuxbash opt]# systemctl stop nginx
[root@linuxbash opt]# ./watchdog.sh nginx
Service nginx is down and now will be started.
[root@linuxbash opt]#
```


---

### 3) анализ логов веб сервера/security лога - (на взлом/скорость ответа/выявление быстрых - медленных запросов, анализ IP адресов и кол-ва запросов от них)
Файлы в репозитории: `nginx.conf`; `access.log`
Скрипты с примерами в тексте.

В качестве `web`-сервера был выбран `nginx`.
Для выявления быстрых и медленных запросов были добавлены в файл конфигурации `/etc/nginx.conf` изменения. Создан дополнительный формат лога `main_req`, к уже существующему предустановленному `main` , в котором добавлено поле `$request_time` самой последней записью файла лога.
https://codedepth.wordpress.com/2017/05/04/nginx-request-time/



---
### 4) крон скрипт с защитой от мультизапуска

### 5) любой скрипт на ваше усмотрение
