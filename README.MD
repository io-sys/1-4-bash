### 1+2) Скрипт watchdog с перезагрузкой процесса/сервиса; watchdog с отсылкой емэйла
Файлы в репозитории: `watchdog.sh`; `var-spool-cron-root`

**watchdog.sh** скрипт, который запускается каждую минуту по `cron` (`/var/spool/cron/root` файл в репозитории `var-spool-cron-root`).
Как работает скрипт, логика:
1) Когда сервис остановлен, скрипт его попытается запустить, если неудача запуска, тогда отправляется `e-mail` с предупрежденим `root`(-у).
2) Если сервис работает и всё в порядке, скрипт напишет `$1 is Active`, когда скрипт запущен вручную, по `cron` процес проверки пройдет тихо.

> **cat /opt/watchdog.sh**
```php
#!/usr/bin/env bash  

lines () {
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
> **crontab -l**
```php
* * * * *  bash /opt/watchdog.sh nginx >/tmp/cron1.log 2>&1 || echo "Failed" | mail -s "nginx doesnt work" root
```

###### Пример: перезапуск или проверка статуса сервиса nginx

> **./watchdog.sh nginx**

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

###### Выполнено в 3(-х) сценариях.
> **1 - На взлом, когда хакеры ищут .xml**

```php
cat /var/log/nginx/access.log | awk 'BEGIN {print "№  ip  -HTTP 404 WHANT TO FINDE XML-"} $9==404 && index($7,".xml")>0{print NR " " $1$7 " - " $4$5}'
```
> **Результат**
```php
[root@linuxbash vagrant]# cat /var/log/nginx/access.log | awk 'BEGIN {print "№  ip  -HTTP 404 WHANT TO FINDE XML-"} $9==404 && index($7,".xml")>0{print NR " " $1$7 " - " $4$5}'
№  ip  -HTTP 404 WHANT TO FINDE XML-
48 10.10.11.20/index.xml - [03/Apr/2019:19:34:51+0000]
50 10.10.11.20/admin.xml - [03/Apr/2019:20:01:21+0000]
51 10.10.11.20/list.xml - [03/Apr/2019:20:01:44+0000]
52 10.10.11.20/sale.xml - [03/Apr/2019:20:01:55+0000]
[root@linuxbash vagrant]#
```

> **2 - скорость ответа, выявление быстрых - медленных запросов.**
Отчет строиться по возрастанию ответа от сервера, самые быстрые ответы вверху, самые медленные ответы внизу.
```php
cat /var/log/nginx/access.log | awk 'BEGIN {print "Query request time"} $25>0.000 {print $25}' | sort |  uniq |  cat -n
```
> **Результат**
```php
[root@linuxbash vagrant]# cat /var/log/nginx/access.log | awk '$25>0.000 {print $25}' | sort |  uniq | awk 'BEGIN {print "Query request time"} {print NR " " $0}'
Query request time
1 0.001
2 0.021
3 0.400
[root@linuxbash vagrant]#
```
> **3 Количество запросов от ip-адресов.**
 Анализ `ip`-адресов и количества запросов от них - количество запросов и `ip`-адрес.
Результат будет упорядочен по убыванию запросов, самый активный `ip`-адрес будет на самом верху. 
```php
cat /var/log/nginx/access.log |  awk '{print $1}' | sort | uniq -c | sort -nr
```
> **Результат**
```php
[root@linuxbash vagrant]# cat /var/log/nginx/access.log |  awk '{print $1}' | sort | uniq -c | sort -nr | awk 'BEGIN {print "Quantity queries from ip addresses"} {print $0}'
Quantity queries from ip addresses
     31 10.10.11.20
     19 10.10.11.21
      2 10.10.11.22
[root@linuxbash vagrant]#
```
---
### 4) Резервное копирование по расписанию, скрипт для cron + защита от мультизапуска
Файлы в репозитории: `./backup_trap.sh`; `var-spool-cron-root`
Для резервного копирования были выбраны каталоги: `/usr`, `/etc` и `/home`

> **cat /opt/backup_trap.sh**
```php
#!/usr/bin/env bash

lockfile=/tmp/lockfile_etcusrhome_ziptask

if ( set -o noclobber; echo "$$" > "$lockfile") 2> /dev/null;
then
   trap 'rm -f "$lockfile"; exit $?' INT TERM EXIT
     # --- Code start.
     tar -cvvzf /var/bkp/bkp-etc--file-$(date +%Y-%m-%d--%H-%M).tar.gz /etc
     tar -cvvzf /var/bkp/bkp-usr--file-$(date +%Y-%m-%d--%H-%M).tar.gz /usr
     tar -cvvzf /var/bkp/bkp-home-file-$(date +%Y-%m-%d--%H-%M).tar.gz /home
     # --- Code end.
     rm -f "$lockfile"
   trap - INT TERM EXIT
else
   echo "Failed to acquire lockfile: $lockfile."
   echo "Held by $(cat $lockfile)"
fi
```
> **Результат**
```php
[root@linuxbash opt]# ./backup_trap.sh
Failed to acquire lockfile: /tmp/lockfile_etcusrhome_ziptask.
Held by 4607
[root@linuxbash bkp]# cat /tmp/lockfile_etcusrhome_ziptask
4607
[root@linuxbash bkp]# ll -h
total 313M
-rw-r--r--. 1 root root 9.5M Apr  4 19:15 bkp-etc--file-2019-04-04--19-15.tar.gz
-rw-r--r--. 1 root root 1.8K Apr  4 19:16 bkp-home-file-2019-04-04--19-16.tar.gz
-rw-r--r--. 1 root root 304M Apr  4 19:16 bkp-usr--file-2019-04-04--19-15.tar.gz
[root@linuxbash bkp]#
```


---
### 5) любой скрипт на ваше усмотрение
