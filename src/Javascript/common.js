//
// Common stuff
// ʕ•ᴥ•ʔ


export const debounce =
  (callback, time = 250, timeoutId) =>
  (...args) =>
  clearTimeout(timeoutId, timeoutId = setTimeout(callback, time, ...args))


export const throttle =
  (callback, time = 250, inTimeout, secondCall, lastestArgs, secondCallTimeoutId) =>
  (...args) => {
    lastestArgs = args

    if (inTimeout) {
      return
    } else if (!secondCall) {
      callback(...lastestArgs)
      secondCall = true
      secondCallTimeoutId = setTimeout(() => secondCall = false, time)
      return
    } else {
      inTimeout = true
    }

    clearTimeout(secondCallTimeoutId)

    setTimeout(() => {
      callback(...lastestArgs)
      inTimeout = false
      secondCall = false
    }, time)
  }
