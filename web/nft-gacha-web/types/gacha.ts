export type Display = {
  description: string;
  name: string;
  thumbnail: {
    cid: string;
    path?: string;
  };
};

export type GachaCollectionItem = {
  id: number;
  name?: string;
  description?: string;
  thumbnail?: string;
  amount: number;
};

export type Transaction = {
  blockId: string;
  errorMessage: string;
  events: Event[];
  status: number;
  statusCode: number;
  statusString: string;
};

export type Event = {
  data: Events;
  eventIndex: number;
  transactionId: string;
  transactionIndex: number;
  type: string;
};

export type Events = IncreceEvent | DecreceEvent | WithdrawEvent | DepositEvent;

export type IncreceEvent = {
  id: string;
  beforeAmount: string;
  afterAmount: string;
};

export type DecreceEvent = IncreceEvent;

export type WithdrawEvent = {
  id: number;
  from: string;
};

export type DepositEvent = {
  id: number;
  to: string;
};
