#!/usr/bin/env fennel

(local fennel (require :fennel))

;; add config directory to fennel.path
(if
  (os.getenv :XDG_CONFIG_HOME)
  (tset fennel :path (.. (os.getenv :XDG_CONFIG_HOME) "/sss/?.fnl;" fennel.path))

  (os.getenv :HOME)
  (tset fennel :path (.. (os.getenv :HOME) "/.config/sss/?.fnl;" fennel.path))

  :else
  (do
    (print "XDG_CONFIG_HOME or HOME is not set, can not resolve config path")
    (os.exit 1)))

;; load config
(local config (require :config))

(local servers (or config.servers {}))
(local default (or config.default {}))

(macro when-str [condition ...]
  "If `condition` is true concatenate `...`, else return an empty string"
  `(if ,condition
     (.. ,...)
     ""))

(fn ibmcloud [action server]
  "Returns the command to start/stop ibmcloud instances"
  (let [command (if (= action :start) :instance-start :instance-stop)]
    (when-str server.ibmcloud
              (..
               ;; login
               (when-str server.ibmcloud.apikey
                         "ibmcloud login --apikey " server.ibmcloud.apikey "\n")
               ;; start/stop instances
               (when-str server.ibmcloud.instances
                         (accumulate [r "" _ instance (ipairs server.ibmcloud.instances)]
                                     (.. r "ibmcloud is " command " " instance "\n")))))))

(fn nm-connect [action server]
  "Returns the command to enable/disable a NetworkManager connection if required"
  (match (type server.vpn)
    :nil    ""

    :string
    (match action
      :up
      (.. "nmcli connection show --active | grep -F " server.vpn
          " || nmcli connection up " server.vpn "\n")
      :down
      (.. "nmcli connection down " server.vpn "\n"))

    :table
    (if
      (and (= :up action)
           server.vpn.up)
      (if
        (= :table (type server.vpn.check))
        (do ; check if any of the listed connections is up, else start the vpn
          (table.insert server.vpn.check server.vpn.up)
          (..
            (table.concat
              (icollect [_ connection (ipairs server.vpn.check)]
                (.. "nmcli connection show --active | grep -F " connection))
              " || ")
            " || nmcli connection up " server.vpn.up  "\n"))
        ;; else
        (.. "nmcli connection show --active | grep -F " server.vpn.up
            " || nmcli connection up " server.vpn.up  "\n"))

      (and (= :down action) ; stop vpn?
           (= :string (type server.vpn.down)))
      (.. "nmcli connection down " server.vpn.down "\n")

      (and (= :down action) ; stop vpn?
           (= true (type server.vpn.down)))
      (.. "nmcli connection down " server.vpn.up "\n")

      ;; else
      "")))

(fn set-bg [action server]
  "Returns the command to (re)set the terminal background color if requested"
  (when-str server.bg
            (if (= action :set)
              (.. "printf '\\e]11;#" server.bg "\\e\\\\'\n")
              "printf '\\e]111;\\e\\\\'\n")))

(fn set-fg [action server]
  "Returns the command to (re)set the terminal foreground color if requested"
  (when-str server.fg
            (if (= action :set)
              (.. "printf '\\e]10;#" server.fg "\\e\\\\'\n")
              "printf '\\e]110;\\e\\\\'\n")))

(fn ssh [server]
  "Returns the command to connect to `server` using ssh"
  (.. (when-str (and server.pass
                     (not server.no-sshpass))
                "sshpass -p '" server.pass "' ")
      (if server.ssh
        (.. server.ssh " ")
        "ssh ")
      (when-str server.opts
                server.opts " ")
      (when-str server.user
                server.user "@")
      server.ip
      "\n"))

(fn c3270 [server]
  "Returns the command to connect to `server` using c3270"
  (.. "c3270 " server.ip " "
      (when-str server.opts
                server.opts " ")
      "\n"))

(fn connect [server ?debug]
  "Create and run a shell script to connect to `server`"
  (let [command
        (..
         (when-str server.env
            server.env "\n\n")

         ;; create cleanup function
         "cleanup(){\ntrue\n"
         (nm-connect :down server)
         (when-str (and server.ibmcloud server.ibmcloud.stop)
                   (ibmcloud :stop server))
         (set-bg :reset server)
         (set-fg :reset server)
         (when-str server.post
                   server.post "\n")
         "rm \"$0\"\n"
         "}\n"
         "trap cleanup EXIT HUP\n\n"

         ;; prepare connection
         (set-bg :set server)
         (set-fg :set server)
         (ibmcloud :start server)
         (nm-connect :up server)
         (when-str server.pre
                   server.pre "\n")
         "\n"

         ;; sleep ?
         (when-str server.sleep
                   "echo 'sleeping " server.sleep " ...'\n"
                   "sleep " server.sleep "\n\n")

         ;; show password ?
         (when-str server.pass
           "printf '\\npassword: \\e[7;8m" server.pass "\\e[0m\\n\\n'\n")

         ;; connect to server
         ((match server.type
            nil ssh
            :ssh ssh
            :c3270 c3270) server))]

    (let [tmpfile (os.tmpname)]
      (with-open [out (io.open tmpfile :w)]
        (out:write command))
      (os.execute (.. (if ?debug "cat " "sh ") tmpfile)))))

(let [?debug (= :--debug (. arg 1))
      s      (if ?debug (. arg 2) (. arg 1))]
  (if
    (= s :--autocomplete)
    (print
      (..
        "complete -W '"
        (accumulate [server-list "" server (pairs servers)]
          (.. server-list " " server))
        "' "
        (string.gsub
          (. arg 0)
          ".*/"
          "")))

    (. servers s)
    (let [server (. servers s)]
      (setmetatable server {:__index (fn [_ key] (. default key))})
      (connect server ?debug))

    :else
    (do
      (print (.. "usage: " (. arg 0) " server"))
      (print)
      (each [s (pairs servers)]
        (print s)))))
