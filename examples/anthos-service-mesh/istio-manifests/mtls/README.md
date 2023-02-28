# mTLS How-To

1. Apply the `loadbalancer.yaml` to create an external load balancer that will route traffic directly.  You should be able to access the app both from the external load balancer IP as well as the ingress gateway IP

2. Apply the `mtls-rules.yaml` which changes the mTLS mode from the default of `PERMISSIVE` (allowing both plaintext and mTLS traffic) to `STRICT` (mTLS only)

3. You should now still be able to access the app from the ingress gateway becuase while your browser talks to the ingress gateway in plaintext, it performs an mTLS handshake with the productpage proxy.  The external load balancer, on the other hand, can only send plaintext requests to productpage, which isn't accepted and hence you will receive a "This site can't be reached" error


## Disabing PeerAuthentication
Update the `mtls-rules.yaml` to set the mTLS mode to `UNSET`, which will revert it back to its [default](https://istio.io/latest/docs/reference/config/security/peer_authentication/#PeerAuthentication-MutualTLS-Mode) behavior (`PERMISSIVE`)
