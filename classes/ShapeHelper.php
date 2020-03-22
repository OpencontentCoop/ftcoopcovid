<?php

class ShapeHelper
{
    private static $instance;

    private $shapes;

    private $basePath = 'extension/ftcoopcovid/comuni_shapes';

    public static function instance()
    {
        if (self::$instance === null){
            self::$instance = new ShapeHelper();
        }

        return self::$instance;
    }

    /**
     * @return string
     */
    public function getBasePath()
    {
        return $this->basePath;
    }

    /**
     * @param string $basePath
     */
    public function setBasePath($basePath)
    {
        $this->basePath = $basePath;
    }

    public function getShape($name)
    {
        $this->listShapes();
        if ($name === '_all'){
            $data = [];
            foreach ($this->shapes as $file){
                $data[] = json_decode(file_get_contents($file['src']), true);
            }

            return json_encode($data);
        }
        if (isset($this->shapes[$name])){
            return file_get_contents($this->shapes[$name]['src']);
        }

        throw new Exception("Shape $name not found");
    }
    
    public function listShapes()
    {
        if ($this->shapes === null){

            $operatorValue = [];
            $fileList = eZDir::recursiveFind($this->basePath, '.json');
            foreach ($fileList as $file){
                $name = str_replace('.json', '', basename($file));
                $this->shapes[$name] = [
                    'name' => $name,
                    'src' => $file,
                    'url' => '/shapes/comune/'. $name,
                ];
            }
            ksort($this->shapes);
        }

        return $this->shapes;
    }
}