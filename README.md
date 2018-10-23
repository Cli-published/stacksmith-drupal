[![View in Stacksmith](https://img.shields.io/badge/view_in-stacksmith-00437B.svg)](https://stacksmith.bitnami.com/p/bitnami-public/apps/99c19450-b505-0136-6be5-226052b6e44c)

# Drupal

This is a simple guide to show how to deploy Drupal using [Bitnami Stacksmith](https://stacksmith.bitnami.com)

## Package and deploy with Stacksmith

1. Go to [stacksmith.bitnami.com](https://stacksmith.bitnami.com).
2. Create a new application and select the `Generic application with DB (MySQL)` stack template.
3. Select the targets you are interested on (AWS, Kubernetes,...).
4. Download Drupal manually from https://www.drupal.org/download-latest/zip, or run the command below:

   ```bash
   wget -O drupal-latest.zip https://www.drupal.org/download-latest/zip
   ```

5. Upload the `drupal-latest.zip` application file (or alternatively `drupal-VERSION.zip`, e.g. `drupal-8.6.2.zip`). Note that you can provide any version of Drupal.
6. Select `Git repository` for the application scripts and paste the URL of this repo. Use `master` as the `Repository Reference`.
7. Click the <kbd>Create</kbd> button.
8. Wait for app to be built and deploy it in your favorite target platform.

Stacksmith will compare the latest commit for a reference (e.g. new commits made to a branch) against the last commit used during packaging. If there are any new commits available, these will be available to view within the `Repository Details` pane in the application history. If you choose to repackage your application, these newer commits will be incorporated and used during the packaging.

### Update the application with Stacksmith

1. Download the latest available version of Drupal from https://www.drupal.org/download-latest/zip, or with the command below:

   ```bash
   wget -O drupal-latest.zip https://www.drupal.org/download-latest/zip
   ```

2. Go to your app [stacksmith.bitnami.com](https://stacksmith.bitnami.com)
3. Click on <kbd>Edit configuration</kbd>, delete the existing `drupal-latest.zip` and upload the new `drupal-latest.zip` (or alternatively `drupal-VERSION.zip`, e.g. `drupal-8.6.2.zip`).
4. Click <kbd>Update</kbd>.
5. Wait for the new version to be built and re-deploy it in your favorite target platform.

Stacksmith will use the latest Application Scripts from the GitHub repository.

## Use the Stacksmith CLI for automating the process

1. Go to [stacksmith.bitnami.com](https://stacksmith.bitnami.com), create a new application and select the `Generic application with DB (MySQL)` stack template.
2. Install [Stacksmith CLI](https://github.com/bitnami/stacksmith-cli) and authenticate with Stacksmith.
3. Download the latest version of Drupal from https://www.drupal.org/download-latest/zip, or with the command below:

   ```bash
   wget -O drupal-latest.zip https://www.drupal.org/download-latest/zip
   ```
4. Edit the `Stackerfile.yml`,  update the `appId` with the URL of your project and the name of `userUploads`.
5. Run the build for a specific target like `aws` or `docker`. E.g.

   ```bash
   stacksmith build --target docker
   ```
6. Wait for app to be built and deploy it in your favorite target platform.

### Update the application via CLI

1. Download the latest version of Drupal from https://www.drupal.org/download-latest/zip, or with the command below:

   ```bash
   wget -O drupal-latest.zip https://www.drupal.org/download-latest/zip
   ```

2. Run the build for a specific target like `aws` or `docker`. E.g.

   ```bash
   stacksmith build --target docker
   ```

3. Wait for the new version to be built and re-deploy it in your favorite target platform.

## Scripts

In the `stacksmith/user-scripts` folder, you can find the required scripts to build and run this application:

### build.sh

This script takes care of configuring the environment for the application to be installed. It performs the following steps:

* Install application dependencies such as Apache, PHP and Composer.
* Uncompress the application code to the `/var/www/html` folder.

### boot.sh

This script takes care of installing the application.

### run.sh

This script starts the Apache server, so that the application can be accessed via HTTP port 80.

## Persisting the application data

In some applications like Drupal you need to store application data in a persistent storage unit. It allows you to keep the uploaded files and other assets in a safe place if the instance or pod goes down. In these cases, you need to customize the `Generic application with DB (MySQL)` stack template depending on the target that you have choosen.

In the steps below you can find a practical case where you add a persistent volume for Kubernetes. Read more about it here: [Creating a Stack Template](https://stacksmith.bitnami.com/+/support/creating-a-stack-template).

### 1. Download the original Kubernetes Helm Chart template

Go to your application build history view, select the build (Kubernetes Target) that you want to customize and click on <kbd>Download Helm Chart</kbd>.

### 2. Make changes in the Kubernetes Helm Chart template

Unpack the downloaded tarball and edit the following files:

* `values.yaml`

  ```diff
  image:
  -  name: **************************
  +  name: @@IMAGE@@
    pullPolicy: IfNotPresent
  ```

  Add at the end of the file:

  ```diff
  +
  +## Enable persistence using Persistent Volume Claims
  +## ref: http://kubernetes.io/docs/user-guide/persistent-volumes/
  +##
  +persistence:
  +  enabled: false
  +  ## Drupal data Persistent Volume Storage Class
  +  ## If defined, storageClassName: <storageClass>
  +  ## If set to "-", storageClassName: "", which disables dynamic provisioning
  +  ## If undefined (the default) or set to null, no storageClassName spec is
  +  ##   set, choosing the default provisioner.  (gp2 on AWS, standard on
  +  ##   GKE, AWS & OpenStack)
  +  ##
  +  # storageClass: "-"
  +  ##
  +  ## If you want to reuse an existing claim, you can pass the name of the PVC using
  +  ## the existingClaim variable
  +  # existingClaim: your-claim
  +  accessMode: ReadWriteOnce
  +  size: 10Gi
  ```

* `templates/deployment.yaml`

  At the end of the file, add a `volumeMount` for the Drupal container and define a new volume.

  ```diff
  +        volumeMounts:
  +        - mountPath: /var/www/html
  +          name: drupal-data
  +      volumes:
  +      - name: drupal-data
  +      {{- if .Values.persistence.enabled }}
  +        persistentVolumeClaim:
  +          claimName: {{ .Values.persistence.existingClaim | default (include "fullname" .) }}
  +      {{- else }}
  +        emptyDir: {}
  +      {{ end }}
  ```

* Create a new file `templates/pvc.yaml` with the following content:

  ```yaml
  {{- if and .Values.persistence.enabled (not .Values.persistence.existingClaim) }}
  kind: PersistentVolumeClaim
  apiVersion: v1
  metadata:
    name: {{ template "fullname" . }}
    labels:
      app: {{ template "fullname" . }}
      chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"
      release: "{{ .Release.Name }}"
      heritage: "{{ .Release.Service }}"
  spec:
    accessModes:
      - {{ .Values.persistence.accessMode | quote }}
    resources:
      requests:
        storage: {{ .Values.persistence.size | quote }}
  {{- if .Values.persistence.storageClass }}
  {{- if (eq "-" .Values.persistence.storageClass) }}
    storageClassName: ""
  {{- else }}
    storageClassName: "{{ .Values.persistence.storageClass }}"
  {{- end }}
  {{- end }}
  {{- end }}
  ```

### 3. Upload your new custom stack template to Stacksmith

Package the files again as a `tar.gz`. Go to `Settings` > `Stack Templates` > `Create a new stack template` and fill the creation form. Upload the new stack template for the Kubernetes target and click on <kbd>Update</kbd>.

### 4. Build your application with the new stack template

Go to your application and click on <kbd>Edit Configuration</kbd>. Select the new stack template that you have just created and click on <kbd>Update</kbd>.

That's all! Stacksmith will repackage Drupal with your custom stack template. When you want to deploy the new Helm Chart, make sure you enable the persistence. Otherwise, it will behave as the generic stack template:

```bash
helm install yourapp.tgz --set persistence.enabled=true
```
