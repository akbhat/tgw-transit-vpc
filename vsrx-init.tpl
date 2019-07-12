#junos-config
groups {
    transit-vpc {
        system {
            root-authentication {
                encrypted-password "$1$ZUlES4dp$OUwWo1g7cLoV/aMWpHUnC/"; ## SECRET-DATA
                ssh-rsa "${SshPublicKey}"; ## SECRET-DATA
                ssh-rsa "${LambdaSshPublicKey}";
            }
            services {
                ssh {
                    connection-limit 5;
                }
            }
        }
    }
}
apply-groups transit-vpc;
system {
    syslog {
        user * {
            any emergency;
        }
        file messages {
            any notice;
            authorization info;
        }
        file interactive-commands {
            interactive-commands any;
        }
    }
}
security {
    policies {
        from-zone trust to-zone trust {
            policy default-permit {
                match {
                    source-address any;
                    destination-address any;
                    application any;
                }
                then {
                    permit;
                }
            }
        }
        from-zone trust to-zone untrust {
            policy default-permit {
                match {
                    source-address any;
                    destination-address any;
                    application any;
                }
                then {
                    permit;
                }
            }
        }
        from-zone untrust to-zone trust {
            policy default-permit {
                match {
                    source-address any;
                    destination-address any;
                    application any;
                }
                then {
                    permit;
                }
            }
        }
    }
    zones {
        security-zone trust {
            tcp-rst;
        }
        security-zone untrust {
            host-inbound-traffic {
                system-services {
                    ike;
                }
                protocols {
                    bgp;
                }
            }
        }
    }
}
