# scp-ant

透過 scp 搬移一堆檔案的小工具


## WHY | 使用情境

```
         TRGET BOARD                                         BUILD SYSTEM
+----------------------------+                       +-------------------------+
| - /usr/local/lib/libxxx.so |====== (network) ======| /sdk/target/rootfs      |
| - /etc/config/xxx.conf     |                       | ├── etc/...             |
| - ...                      |                       | └── usr                 |
+----------------------------+                       |     └── local           |
                                                     |          `── lib/...    |
                                                     +-------------------------+
```

在嵌入式系統開發新功能時，有時候會在某一台 target 設備上直接實作功能。當功能完成後，就需要將開發過程中變動的檔案取出，然後安裝到編譯系統 (或者說 SDK) 中。這樣下回由編譯系統產生的韌體才會加入這個新功能。

我通常會使用 scp 將檔案系統中的更新檔，一個個複製到另一台主機上的某個目錄 ex: `/home/ant/target/rootfs`。複製完後會在 rootfs/ 下看見所有的檔案。可以將整個 rootfs tar 起來做成 zip 解壓安裝包，或是交給 build sysem 的維護者安裝到 sdk 中。

因為檔案可能分散在檔案系統中的不同目錄，如果要一個個處理，會花許多時間。


## WHAT | scp-ant 在幹嘛

scp-ant 只是一支 bash script，使用前您需要修改程式碼中的變數。改成你要複製過去的目標主機目錄即可

```
rmt_host="你的 ssh-server ip 地址"
rmt_user="登入 ssh-server 的帳號"
rmt_port="ssh 使用的 port"
rmt_basedir="想要將檔案複製到哪個資料夾下"
sshpass_passwd="ssh 登入密碼"
```

file_list 則是你想要從裝置端取出，並傳送到遠端伺服器目錄的檔案清單

```
file_list="
	/usr/include/xxx.h
	/usr/local/lib/libxxx.so
	/usr/local/sbin/dispatcher.sh
	/root/.ssh/authorized_keys
	/etc/config/xxx.conf
	/no/such/file.txt    # 這裡刻意寫了一個不存在的檔案
"
```

做好設定後，一旦執行，scp-ant 就會解析你想要複製的檔案路徑，例如:

發現你要傳送 `/usr/local/lib/libxxx.so`，就會先在遠端主機的 `/home/ant/target/rootfs` 目錄下先建立 `usr/local/lib` 資料夾，接著將 libxxx.so 以 scp 複製過去。

完成後，在 /home/ant/target/rootfs 下就會有對應裝置端檔案系統的修改檔列表。


## DEMO | 執行方式

遠端主機的目錄原本是空的

```
$ tree -a /home/ant/target/rootfs
/home/ant/target/rootfs

0 directories, 0 files

```

將 scp-ant.sh 複製到裝置端，設定好變數和 file_list 清單。以下檔案是我要從裝置端，複製到遠端主機的 /home/ant/target/rootfs/ 下

```
file_list="
	/usr/include/utils.h
	/usr/local/lib/libtest.so
	/usr/local/sbin/agent
	/usr/local/sbin/dispatcher.sh
	/root/.ssh/authorized_keys
	/root/.ssh/id_rsa
	/etc/config/teleport
	/usr/local/sbin/gentunnel
	/no/such/file.txt           # 這裡刻意寫了一個不存在的檔案
	/etc/init.d/diag
	/etc/init.d/agent
"
```

執行:

```
# ./scp-ant.sh
MKDIR> /usr/include
SCP>   /usr/include/utils.h -> 10.1.1.123
MKDIR> /usr/local/lib
SCP>   /usr/local/lib/libtest.so -> 10.1.1.123
MKDIR> /usr/local/sbin
SCP>   /usr/local/sbin/agent -> 10.1.1.123
MKDIR> /usr/local/sbin
SCP>   /usr/local/sbin/dispatcher.sh -> 10.1.1.123
MKDIR> /root/.ssh
SCP>   /root/.ssh/authorized_keys -> 10.1.1.123
MKDIR> /root/.ssh
SCP>   /root/.ssh/id_rsa -> 10.1.1.123
MKDIR> /etc/config
SCP>   /etc/config/teleport -> 10.1.1.123
MKDIR> /usr/local/sbin
SCP>   /usr/local/sbin/gentunnel -> 10.1.1.123
ERRO>  NO such file: /no/such/file.txt          # 有被檢查出來
MKDIR> /etc/init.d
SCP>   /etc/init.d/diag -> 10.1.1.123
MKDIR> /etc/init.d
SCP>   /etc/init.d/agent -> 10.1.1.123
DONE :)
```

執行完後 /home/ant/target/rootfs 下就有所有檔案了

```
$ tree -a /home/ant/target/rootfs/
/home/ant/target/rootfs/
├── etc
│   ├── config
│   │   └── teleport
│   └── init.d
│       ├── agent
│       └── diag
├── root
│   └── .ssh
│       ├── authorized_keys
│       └── id_rsa
└── usr
    ├── include
    │   └── utils.h
    └── local
        ├── lib
        │   └── libtest.so
        └── sbin
            ├── agent
            ├── dispatcher.sh
            └── gentunnel

10 directories, 10 files
```
