pub contract Calculate {
  pub event Add(_ num1: Int64, _ num2: Int64, result: Int64)

  pub fun add(_ num1: Int64, _ num2: Int64): Int64 {
    let total = num1 + num2
    emit Add(num1, num2, result: total)
    return total
  }

  init() {}
}
