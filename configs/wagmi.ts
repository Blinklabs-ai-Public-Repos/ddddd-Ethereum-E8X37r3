import { http, webSocket, createConfig } from "wagmi";
import { injected } from "wagmi/connectors";

import config from "@/uiconfig.json";

const setupConfig = () => {
  const chain = config.chain;
  
  let rpcUrls: { default: { http: string[]; websocket: string[] } } = {
    default: { http: [chain.rpc], websocket: [] },
  };
  if (chain.rpc.includes("wss")) {
    rpcUrls = { default: { http: [], websocket: [chain.rpc] } };
  }

  const chainConfig = {
    ...chain,
    rpcUrls,
  };
  return chainConfig;
};

const chainConfig = setupConfig();

export const wagmiConfig = createConfig({
  chains: [chainConfig],
  connectors: [injected()],
  transports: {
    [chainConfig.id]: chainConfig.rpc.includes("http") ? http() : webSocket(),
  },
});
