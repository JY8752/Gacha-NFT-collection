/// NFTコレクションにガチャによる抽選機能を追加する
pub contract Gacha {
  /// NFTに数量の属性を追加する
  pub resource interface NFTAmount {
    pub var amount: UInt32

    pub fun incrementAmount(amount: UInt32)
    pub fun decreseAmount(amount: UInt32) {
      pre {
        self.amount - amount >= 0: "decrease result is negative."
      }
    }
  }

  /// NFTを抽選する
  pub resource interface Lottery {
    pub fun lotteryMint()
  }
}
 