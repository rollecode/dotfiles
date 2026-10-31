// Chromium 157 shows DRM AV1 as black video: github.com/brave/brave-browser/issues/57885
const isAv1 = (type) => /av01/i.test(String(type));

const isTypeSupported = MediaSource.isTypeSupported.bind(MediaSource);
MediaSource.isTypeSupported = (type) => !isAv1(type) && isTypeSupported(type);

const canPlayType = HTMLMediaElement.prototype.canPlayType;
HTMLMediaElement.prototype.canPlayType = function (type) {
  if (isAv1(type)) {
    return '';
  }

  return canPlayType.call(this, type);
};

const decodingInfo = MediaCapabilities.prototype.decodingInfo;
MediaCapabilities.prototype.decodingInfo = function (config) {
  if (isAv1(config?.video?.contentType)) {
    return Promise.resolve({ supported: false, smooth: false, powerEfficient: false });
  }

  return decodingInfo.call(this, config);
};
