;;; sss example config
;; all parameters are optional, unless specified

{;; when a server doesn't have a setting, the value from the default table is used
 ;; this table is optional
 :default {:bg :123456
           :opts "-o StrictHostKeyChecking=accept-new"} ; automatically accept new hosts

 ;; the servers table contains all ssh and 3270 servers
 :servers
  {:example1 {:ip :1.2.3.4      ; or hostname (required)
              :user :root       ; ssh username
              :pass :adcdd      ; ssh password
              :bg :0000ff       ; background color
              :env :TERM=xterm  ; modify the environment
              :opts ""          ; additional ssh options
              :vpn :ExampleVPN} ; start this NetworkManager connection
   :example2 {:ip :exmaple2.example
              :vpn {:up "vpn"                            ; start this NetworkManager connection,
                    :check ["connection1" "connection2"] ; (optional) but not if any of these connections are active
                    :down "vpn"}}                        ; (optional) stop this connection when disconnectng, true=started connection
   :3270 {:ip :zos.example          ; required
          :type :c3270              ; required to use c3270 for this connection
          :opts "3270 -defaultfgbg" ; additional c3270 options
          :bg :000000}
   :wazi {:ip :cloud.example        ; required
          :sleep :8m                ; wait 8 minutes between starting the instances and connecting
          :ibmcloud {:apikey ""                     ; ibmcloud api key
                     :instances [:server1 :server2] ; start (and stop) these instances
                     :stop false}}}}                ; don't stop the started instances
