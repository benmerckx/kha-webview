package khaweb;

#if (sys_html5 || sys_debug_html5)

import js.html.IFrameElement;
import js.Browser.*;

abstract WebView(IFrameElement) {

	inline function new(iframe: IFrameElement)
		this = iframe;

	public static function create(callback: WebView -> Void) {
		var iframe: IFrameElement = cast document.createElement(
			#if sys_debug_html5 'webview' #else 'iframe' #end
		);
		iframe.setAttribute('allowtransparency', 'true');
		iframe.style.position = 'absolute';
		iframe.style.top = '0';
		iframe.style.left = '0';
		iframe.style.width = '100%';
		iframe.style.height = '100%';
		iframe.style.border = 'none';
		document.body.appendChild(iframe);
		callback(new WebView(iframe));
	}

	inline public function loadAsset(filename: String) {
		var url = window.location.href;
		url = url.substr(0, url.length - 'index.html'.length);
		this.src = '$url$filename';
	}

	inline public function loadUrl(url: String)
		this.src = url;

	public function loadData(data: String, ?mimeType: String, ?encoding: String) {
		if (mimeType == null) mimeType = 'text/html';
		if (encoding == null) encoding = 'utf-8';
		this.src = 'data:$mimeType;charset=$encoding,'+StringTools.urlEncode(data);
	}

	inline public function evaluateJavascript(script: String, callback: String -> Void)
		#if sys_debug_html5
		(cast this).executeJavaScript(script, false, function(res) 
			callback(haxe.Json.stringify(res))
		);
		#else
		callback(haxe.Json.stringify(
			(cast this.contentWindow).eval(script)
		));
		#end

	inline public function onMessage(listener: String -> Void)
		window.addEventListener('message', function (e)
			if (e.source == this.contentWindow) listener(e.data)
		, false);

	inline public function postMessage(message: String)
		this.contentWindow.postMessage(message, this.src);

}

#elseif sys_android

import com.ktxsoftware.kha.KhaActivity;
import android.view.View;
import java.util.concurrent.CountDownLatch;
import java.Lib;
import java.lang.Runnable;

@:forward(loadUrl, loadData)
abstract WebView(WebkitView) {

	function new(activity: Activity) {
		var view = new WebkitView(activity);
		view.getSettings().setJavaScriptEnabled(true);
		view.setBackgroundColor(0x00000000);
		var params = new LayoutParams(LayoutParams.FILL_PARENT, LayoutParams.FILL_PARENT);
		activity.addContentView(view, params);
		this = view;
	}

	public static function create(callback: WebView -> Void)
		KhaActivity.the().runOnUiThread(new RunnableTask(function ()
			callback(new WebView(cast KhaActivity.the()))
		));

	public function loadAsset(filename: String)
		this.loadUrl('file:///android_asset/$filename');

	public function evaluateJavascript(script: String, callback: String -> Void)
		this.evaluateJavascript(script, new ValueCallbackTask(callback));

	public function onMessage(listener: String -> Void)
		this.addJavascriptInterface(new JavascriptInterfaceTask(listener), 'khawebview');

	public function postMessage(message: String) {
		// todo
	}

}

@:classCode('
	@JavascriptInterface
	public void post(String v) {
		this.postMessage(v);
	}
')
private class JavascriptInterfaceTask {
	var task: String -> Void;
	public function new(task) this.task = task;
	function postMessage(v) task(v);
}

private class RunnableTask implements Runnable {
	var task: Void -> Void;
	public function new(task) this.task = task;
	public function run() task();
}

private class ValueCallbackTask<T> implements ValueCallback<T> {
	var task: T -> Void;
	public function new(task) this.task = task;
	public function onReceiveValue(v) task(v);
}

@:native('android.webkit.WebSettings')
private extern class WebSettings {
	function setJavaScriptEnabled(flag: Bool): Void;
}

@:native('android.webkit.WebView')
private extern class WebkitView extends View {
	function new(ctx: android.content.Context): Void;
	function getSettings(): WebSettings;
	function loadUrl(url: String): Void;
	function setBackgroundColor(color: Int): Void;
	function loadData(data: String, ?mimeType: String, ?encoding: String): Void;
	function evaluateJavascript(script: String, callback: ValueCallback<String>): Void;
	function addJavascriptInterface(object: Dynamic, name: String): Void;
}

@:native('android.webkit.ValueCallback')
private extern interface ValueCallback<T> {
	function onReceiveValue(value: T): Void;
}

@:native('android.view.ViewGroup.LayoutParams')
private extern class LayoutParams {
	static var FILL_PARENT: Int;
	function new(w: Int, h: Int): Void;
}

@:native('android.app.Activity')
private extern class Activity extends android.app.Activity {
	function addContentView(view: View, params: LayoutParams): Void;
}

#end