async function __wrapper(functionName, env = '{}', arguments = '{}') {
    let callFunction = new Function('env', 'arguments', `
        return ${functionName}(JSON.parse(env), JSON.parse(arguments));
    `);
    return JSON.stringify(await callFunction(env, arguments));
}